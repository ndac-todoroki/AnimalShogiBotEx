defmodule AnimalShogiEx.Game.Server do
  @moduledoc """
  Server which connects to the AnimalShogi server and plays with it.
  """

  alias AnimalShogiEx.{Game, Position, Piece, Fighter, Move}
  alias Game.State

  require Piece
  require Move

  use GenServer

  defstruct [:game_state, :game_id, :socket]

  @type t :: %__MODULE__{
          game_state: State.t(),
          game_id: String.t(),
          socket: Port.t()
        }

  @type t_pre :: %__MODULE__{
          game_state: State.t(),
          game_id: String.t() | nil,
          socket: Port.t()
        }

  @domain 'shogi.keio.app'
  @port 80

  def start_link(_), do: GenServer.start_link(Game.Server, [])

  @impl GenServer
  @spec init(any) :: {:ok, t_pre}
  def init(_) do
    {:ok, socket} = :gen_tcp.connect(@domain, @port, [:binary, {:packet, 0}, {:active, true}])

    {:ok, %__MODULE__{game_state: State.initial_board(), socket: socket}}
  end

  @impl GenServer
  def handle_call({:move, {%Position{} = from, %Position{} = to}}, _from, %__MODULE__{} = state) do
    # TODO: 3. ひよこを最前列までオプション無しで持っていった場合(初回)は {:error, :set_promotion}
    try_move(state, from, to)
  end

  @impl GenServer
  def handle_call({:move, {%Position{} = from, direction}}, _from, state)
      when Move.is_direction(direction) do
    with {:ok, to} <- from |> Position.add(direction |> Move.to_vector()) do
      try_move(state, from, to)
    else
      _ -> {:reply, {:error, :out_of_bounds}, state}
    end
  end

  @impl GenServer
  def handle_call({:move, {%Position{} = from, %Position{} = to}, promotion}, _from, state) do
    # TODO: 駒がひよこ以外なら {:error, :not_hiyoko} か 暗黙の除去か …おそらく前者のが明示的で良い
    try_move(state, from, to, promotion)
  end

  @impl GenServer
  def handle_call({:move, {%Position{} = from, direction}, promotion}, _from, state)
      when Move.is_direction(direction) do
    with {:ok, to} <- from |> Position.add(direction |> Move.to_vector()) do
      try_move(state, from, to, promotion)
    else
      _ -> {:reply, {:error, :out_of_bounds}, state}
    end
  end

  @impl GenServer
  def handle_call({:drop, {%Piece{} = piece, %Position{} = at}}, _from, %__MODULE__{} = state) do
    # TODO: 持っていない駒を置こうとしたら {:error, :nonexistent}

    cond do
      State.vacant?(state.game_state, at) == false ->
        {:reply, {:error, :not_vacant}, state}

      State.in_hand?(state.game_state, piece) == false ->
        {:reply, {:error, :not_in_hand}, state}

      :else ->
        message =
          State.prefix(state.game_state) <> Piece.as_sigil(piece) <> "*" <> Position.to_string(at)

        state.socket |> :gen_tcp.send(message |> String.to_charlist())

        state = state
        {:reply, {:ok, state}, state}
    end
  end

  @impl GenServer
  def handle_cast(:accept, %__MODULE__{socket: sock} = state) do
    IO.puts("** Accepting...")
    sock |> :gen_tcp.send("ACCEPT" |> String.to_charlist())
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:tcp, _socket,
         "BEGIN Game_Summary\nGame_ID:" <>
           <<game_id::bytes-size(17)>> <> "\nYour_Turn:" <> "-" <> "\nEND Game_Summary\n"},
        %__MODULE__{} = state
      ) do
    state = put_in(state.game_state.first?, false)
    state = %{state | game_id: game_id, game_state: state.game_state |> State.next_turn()}

    IO.puts("""
    Game ID: #{game_id}
    First move: Opponent
    """)

    IO.puts(inspect state.game_state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:tcp, _socket,
         "BEGIN Game_Summary\nGame_ID:" <>
           <<game_id::bytes-size(17)>> <> "\nYour_Turn:" <> "+" <> "\nEND Game_Summary\n"},
        %__MODULE__{} = state
      ) do
    state = put_in(state.game_state.first?, true)
    state = %{state | game_id: game_id, game_state: state.game_state |> State.next_turn()}

    IO.puts("""
    Game ID: #{game_id}
    First move: YOU!
    """)

    IO.puts(inspect state.game_state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:tcp, _socket,
         <<player::bytes-size(1)>> <>
           <<type::bytes-size(1)>> <> "*" <> <<at::bytes-size(2)>> <> ",OK\n"},
        %__MODULE__{} = state
      )
      when player in ~w(+ -) and type in ~w(h z k) do
    with {:ok, at} <- at |> convert_to_position(state) do
      player = current_player(state, player)

      # BAD BAD CODE
      state = state |> drop_fighter(player, Piece.from_type(type), at) |> elem(1)
      IO.puts(inspect state.game_state)
      IO.puts("#{player} dropped #{type} to #{inspect at}")

      {:noreply, state}
    else
      {:error, :out_of_bounds} ->
        IO.puts("** out of bounds error on DROP")
        IO.puts("     at: #{at}")

        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(
        {:tcp, _socket,
         <<player::bytes-size(1)>> <> <<from::bytes-size(2)>> <> <<to::bytes-size(2)>> <> ",OK\n"},
        %__MODULE__{} = state
      )
      when player in ~w(+ -) do
    do_move(state, from, to, false)
  end

  @impl GenServer
  def handle_info(
        {:tcp, _socket,
         <<player::bytes-size(1)>> <> <<from::bytes-size(2)>> <> <<to::bytes-size(2)>> <> "+,OK\n"},
        %__MODULE__{} = state
      )
      when player in ~w(+ -) do
    do_move(state, from, to, true)
  end

  @impl GenServer
  def handle_info(
        {:tcp, _socket,
         <<player::bytes-size(1)>> <>
           <<from::bytes-size(2)>> <>
           <<to::bytes-size(2)>> <> ",OK\n" <> "#GAME_OVER\n#" <> result},
        %__MODULE__{} = state
      )
      when player in ~w(+ -) and result in ~w(WIN LOSE) do
    IO.puts("""
    GAME OVER!

    You #{result}
    """)

    do_move(state, from, to, false)
  end

  @impl GenServer
  def handle_info({:tcp, _socket, "#GAME_OVER\n#" <> result}, %__MODULE__{} = state)
      when result in ~w(WIN LOSE) do
    IO.puts("""
    GAME OVER!

    #{inspect state.game_state}

    You #{result}
    """)
  end

  @impl GenServer
  def handle_info({:tcp, _socket, packet}, %__MODULE__{} = state) do
    IO.inspect(packet, label: "incoming packet")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:tcp_closed, _socket}, %__MODULE__{} = state) do
    IO.inspect("Socket has been closed")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:tcp_error, socket, reason}, state) do
    IO.inspect(socket, label: "connection closed dut to #{reason}")
    {:noreply, state}
  end

  #
  # PRIVATE FUNCTIONS
  #

  defp try_move(%{game_state: game_state} = state, from, to, promotion \\ false) do
    with %Fighter{owner: :player} <- State.fighter_by_position(game_state, from) do
      case State.fighter_by_position(game_state, to) do
        %Fighter{owner: :player} ->
          {:reply, {:error, :invalid_move}, state}

        _ ->
          if State.valid_move?(state.game_state, from, to) do
            message =
              State.prefix(state.game_state) <>
                Position.to_string(from) <>
                Position.to_string(to) <> if(promotion, do: "+", else: "")

            state.socket |> :gen_tcp.send(message |> String.to_charlist())

            state = state
            {:reply, {:ok, state}, state}
          else
            {:reply, {:error, :invalid_move}, state}
          end
      end
    else
      :none ->
        {:reply, {:error, :nonexistent}, state}

      %Fighter{} ->
        {:reply, {:error, :not_yours}, state}
    end
  end

  @spec convert_to_position(String.t(), %__MODULE__{}) :: {:ok, Position.t()}
  defp convert_to_position(pos_str, %__MODULE__{} = state) do
    with {:ok, position} <- Position.new(pos_str) do
      if state.game_state.first? do
        {:ok, position}
      else
        {:ok, position |> Position.inverse()}
      end
    end
  end

  @spec move_fighter(%__MODULE__{}, Position.t(), Position.t(), boolean) ::
          {:ok, %__MODULE__{}} | {:error, :invalid_move | :no_target | :nonexistent}
  defp move_fighter(
         %__MODULE__{game_state: game_state} = state,
         %Position{} = from,
         %Position{} = to,
         naru?
       ) do
    with %Fighter{owner: owner} = fighter <- State.fighter_by_position(game_state, from) do
      case State.fighter_by_position(game_state, to) do
        %Fighter{owner: target_owner} when target_owner == owner ->
          {:error, :invalid_move}

        %Fighter{} ->
          with {:ok, %__MODULE__{} = new_state} <- capture_fighter(state, to, owner) do
            game_state =
              new_state.game_state
              |> State.move_fighter(from, to)
              |> State.next_turn()
              |> perform_nari(fighter, from, naru?)

            {:ok, %{new_state | game_state: game_state}}
          end

        :none ->
          game_state =
            game_state
            |> State.move_fighter(from, to)
            |> State.next_turn()
            |> perform_nari(fighter, from, naru?)

          {:ok, %{state | game_state: game_state}}
      end
    else
      :none ->
        {:error, :nonexistent}
    end
  end

  defp perform_nari(
         %Game.State{} = state,
         %Fighter{piece: %Piece{type: Piece.Hiyoko}, owner: owner},
         position,
         true
       ) do
    state
    |> State.remove_fighter_at(position)
    |> State.add_fighter_at(Piece.new(Piece.Niwatori), owner, position)
  end

  defp perform_nari(%Game.State{} = state, _piece, _position, _naru?), do: state

  @spec capture_fighter(%__MODULE__{}, Position.t(), :player | :opponent) ::
          {:ok, %__MODULE__{}} | {:error, :no_target}
  defp capture_fighter(%__MODULE__{game_state: game_state} = state, %Position{} = at, owner) do
    with %Fighter{} = fighter <- State.fighter_by_position(game_state, at) do
      game_state =
        game_state
        |> State.add_to_hand(fighter.piece, owner)
        |> State.remove_fighter_at(at)

      {:ok, %{state | game_state: game_state}}
    else
      :none ->
        {:error, :no_target}
    end
  end

  @spec drop_fighter(%__MODULE__{}, :player | :opponent, Piece.t(), Position.t()) ::
          {:ok, %__MODULE__{}} | {:error, :not_vacant}
  defp drop_fighter(%__MODULE__{game_state: game_state} = state, owner, %Piece{} = piece, at)
       when is_atom(owner) do
    with true <- game_state |> State.vacant?(at) do
      game_state =
        game_state
        |> State.add_fighter_at(piece, owner, at)
        |> State.next_turn()

      {:ok, %{state | game_state: game_state}}
    else
      false -> {:error, :not_vacant}
    end
  end

  @spec current_player(%__MODULE__{}, String.t()) :: :player | :opponent
  defp current_player(%__MODULE__{} = state, <<signal::bytes-size(1)>>),
    do: if(State.prefix(state.game_state) == signal, do: :player, else: :opponent)

  # cut-out for MOVE actions.
  @spec do_move(t, String.t(), String.t(), boolean) :: {:noreply, t}
  defp do_move(state, from, to, naru?) do
    with {:ok, from} <- from |> convert_to_position(state),
         {:ok, to} <- to |> convert_to_position(state),
         {:ok, state} <- state |> move_fighter(from, to, naru?) do
      IO.puts(inspect state.game_state)
      {:noreply, state}
    else
      {:error, :out_of_bounds} ->
        IO.puts("** out of bounds error on MOVE")
        IO.puts("     from: #{from}")
        IO.puts("     to:   #{to}")

        {:noreply, state}

      {:error, other_errors} ->
        IO.puts("** #{other_errors} error on MOVE")
        IO.puts("     from: #{from}")
        IO.puts("     to:   #{to}")

        {:noreply, state}
    end
  end
end
