defmodule AnimalShogiEx.Game.State do
  @moduledoc """
  Struct of the AnimalShogi game state.
  """

  alias AnimalShogiEx.{Fighter, Piece, Position, Vector, Move, Possibility}
  alias __MODULE__, as: State

  require Piece
  require Move
  require Fighter

  defstruct ~w(fighters my_hand his_hand turn first?)a

  @type t :: %__MODULE__{
          fighters: fighters,
          my_hand: pieces,
          his_hand: pieces,
          turn: non_neg_integer,
          first?: boolean
        }

  @type fighters :: [Fighter.t()]
  @type pieces :: [Piece.t()]

  def initial_board do
    {:ok, hiyoko_pos} = Position.new("2c")
    {:ok, zo_pos} = Position.new("1d")
    {:ok, lion_pos} = Position.new("2d")
    {:ok, kirin_pos} = Position.new("3d")

    %__MODULE__{
      fighters: [
        # Player's fighters
        Fighter.new(Piece.Hiyoko, hiyoko_pos, :player),
        Fighter.new(Piece.Zo, zo_pos, :player),
        Fighter.new(Piece.Lion, lion_pos, :player),
        Fighter.new(Piece.Kirin, kirin_pos, :player),

        # Opponent's fighters
        Fighter.new(Piece.Hiyoko, hiyoko_pos |> Position.inverse(), :opponent),
        Fighter.new(Piece.Zo, zo_pos |> Position.inverse(), :opponent),
        Fighter.new(Piece.Lion, lion_pos |> Position.inverse(), :opponent),
        Fighter.new(Piece.Kirin, kirin_pos |> Position.inverse(), :opponent)
      ],
      my_hand: [],
      his_hand: [],
      turn: 0,
      first?: true
    }
  end

  @doc """
  A prefix for performing actions. If you're first it will return `"+"`, otherwise `"-"`.
  """
  @spec prefix(State.t()) :: String.t()
  def prefix(%__MODULE__{first?: true}), do: "+"
  def prefix(%__MODULE__{first?: false}), do: "-"

  @doc """
  Whether if you have the posed `Piece` in your hand.

  ### Example

      iex> state |> State.in_hand?(Piece.Hiyoko)
      false

  This will return false even if that Piece can never appear in the hand.
  """
  @spec in_hand?(State.t(), Piece.t()) :: boolean
  def in_hand?(%__MODULE__{my_hand: hand}, %Piece{} = piece),
    do: hand |> Enum.any?(&(&1 == piece))

  @spec add_to_hand(State.t(), Piece.t(), :player | :opponent) :: State.t()
  def add_to_hand(%__MODULE__{} = state, %Piece{} = piece, owner)
      when owner in ~w(player opponent)a do
    case owner do
      :opponent -> %{state | his_hand: [piece | state.his_hand]}
      :player -> %{state | my_hand: [piece | state.my_hand]}
    end
  end

  @doc """
  Increments the turn integer by one.

  ### Example

      iex> state.turn
      10

      iex> state = state |> State.next_turn
      :ok

      iex> state.turn
      11

  """
  @spec next_turn(State.t()) :: State.t()
  def next_turn(%__MODULE__{} = state), do: update_in(state.turn, &(&1 + 1))

  @doc """
  Whether you can put a piece on the given point or not.

  ### Example

      iex> position = %Position{column: 1, row: 0}
      iex> state |> State.vacant?(position)
      false

  """
  @spec vacant?(State.t(), Position.t()) :: boolean
  def vacant?(%__MODULE__{fighters: fighters}, %Position{} = position),
    do: Enum.all?(fighters, &(&1.position != position))

  @doc """
  Determines whether there are any player's Piece on the given position.
  """
  @spec mine?(State.t(), Position.t()) :: boolean
  def mine?(%__MODULE__{} = state, %Position{} = position) do
    state
    |> fighter_by_position(position)
    |> case do
      %Fighter{owner: :player} -> true
      _ -> false
    end
  end

  @doc """
  Determines whether there are any opponent's Piece on the given position.
  """
  @spec his?(State.t(), Position.t()) :: boolean
  def his?(%__MODULE__{} = state, %Position{} = position) do
    state
    |> fighter_by_position(position)
    |> case do
      %Fighter{owner: :opponent} -> true
      _ -> false
    end
  end

  @doc """
  Will be false if the piece can not move that way, or if the player's piece is already at `to`.
  """
  @spec valid_move?(State.t(), Position.t(), Position.t()) :: boolean()
  def valid_move?(%__MODULE__{} = state, %Position{} = from, %Position{} = to) do
    fighter = state |> fighter_by_position(from)

    # TODO: do out of bounds check too
    #   currently it is done at position creation (the game state does not hold game size)
    with {:ok, direction} <- Position.diff(from, to) |> Vector.to_move() do
      Piece.moveable?(fighter.piece, direction) and not mine?(state, to)
    else
      {:error, :undefined_move} -> false
    end
  end

  @spec valid_move?(State.t(), Position.t(), Move.direction()) :: boolean()
  def valid_move?(%__MODULE__{} = state, %Position{} = from, direction)
      when Move.is_direction(direction) do
    with {:ok, to} <- from |> Position.add(direction |> Move.to_vector()) do
      fighter = state |> fighter_by_position(from)
      Piece.moveable?(fighter.piece, direction) and not mine?(state, to)
    else
      _ -> false
    end
  end

  @doc """
  Moves a fighter pointed at a `Position` to the desired `Position`, with the assumption that the `to` position is correct.
  To check the move could be performed, use `valid_move?/3` beforehand.
  """
  @spec move_fighter(State.t(), Position.t(), Position.t()) :: State.t()
  def move_fighter(%__MODULE__{} = state, %Position{} = from, %Position{} = to) do
    fighter = fighter_by_position(state, from)

    %{state | fighters: state.fighters |> State.Fighters.move(fighter, to)}
  end

  @spec fighter_by_position(State.t(), Position.t()) :: Fighter.t() | :none
  def fighter_by_position(%__MODULE__{fighters: fighters}, position),
    do: Enum.find(fighters, :none, fn %Fighter{position: p} -> p == position end)

  def remove_fighter_at(state, at),
    do: %{state | fighters: state.fighters |> State.Fighters.remove(at)}

  def add_fighter_at(state, %Piece{} = piece, owner, at) when Fighter.is_owner(owner),
    do: %{state | fighters: state.fighters |> State.Fighters.add(Fighter.new(piece, at, owner))}

  @spec available_moves(State.t()) :: [Possibility.t()]
  def available_moves(%State{fighters: fighters} = state) do
    fighters
    |> Enum.filter(&(&1.owner == :player))
    |> Enum.map(&{&1, &1 |> Fighter.available_moves()})
    |> Enum.flat_map(fn {f, f_dirs} -> Enum.map(f_dirs, fn d -> {f, d} end) end)
    |> Enum.map(fn {%{position: p} = f, dir} ->
      target = Position.add(p, dir |> Move.to_vector())
      {f, dir, target}
    end)
    |> Enum.map(fn
      {fighter, direction, {:ok, position}} ->
        {fighter, direction, fighter_by_position(state, position)}

      _else ->
        nil
    end)
    |> Enum.reject(&(&1 == nil))
    |> Enum.reject(fn
      {f, _d, %Fighter{} = t} -> f.owner == t.owner
      _ -> false
    end)
    |> Enum.map(&Possibility.new/1)
  end
end

defmodule AnimalShogiEx.Game.State.Fighters do
  @moduledoc """
  Functions for moving Fighters with ease.
  """

  alias AnimalShogiEx.{Fighter, Position}
  alias AnimalShogiEx.Game.State

  @spec move(State.fighters(), Fighter.t(), Position.t()) :: State.fighters()
  def move(fighters, %Fighter{} = fighter, %Position{} = to) when is_list(fighters),
    do: [%{fighter | position: to} | fighters |> Enum.reject(&(&1 == fighter))]

  @spec remove(State.fighters(), Position.t()) :: State.fighters()
  def remove(fighters, %Position{} = at) when is_list(fighters),
    do: fighters |> Enum.reject(&(&1.position == at))

  @spec remove(State.fighters(), Fighter.t()) :: State.fighters()
  def remove(fighters, %Fighter{position: position}) when is_list(fighters),
    do: remove(fighters, position)

  @spec add(State.fighters(), Fighter.t()) :: State.fighters()
  def add(fighters, %Fighter{} = fighter) when is_list(fighters), do: [fighter | fighters]
end

defimpl Inspect, for: AnimalShogiEx.Game.State do
  alias AnimalShogiEx.Game.State
  alias AnimalShogiEx.{Position, Piece}

  require Integer

  def inspect(%State{} = state, _) do
    list = state |> to_game_map
    hand = state |> hand_list
    last_player = if Integer.is_even(state.turn) == state.first?, do: "Player", else: "Opponent"

    """
    Turn #{state.turn} : #{last_player}'s move result

            1   2   3
          +---+---+---+
       a  |#{list |> Enum.at(0) |> Enum.join("|")}|
          +---+---+---+
       b  |#{list |> Enum.at(1) |> Enum.join("|")}|
          +---+---+---+
       c  |#{list |> Enum.at(2) |> Enum.join("|")}|
          +---+---+---+
       d  |#{list |> Enum.at(3) |> Enum.join("|")}|
          +---+---+---+

     hands: #{hand |> Enum.join(" ")}
    """
  end

  defp to_game_map(%State{} = state) do
    ~w(1a 2a 3a 1b 2b 3b 1c 2c 3c 1d 2d 3d)
    |> Enum.map(&Position.new/1)
    |> Enum.map(fn {:ok, pos} -> pos end)
    |> Enum.map(&State.fighter_by_position(state, &1))
    |> Enum.map(fn
      %{owner: :player, piece: p} -> "￪" <> Piece.as_emoji(p)
      %{owner: :opponent, piece: p} -> "￬" <> Piece.as_emoji(p)
      :none -> "   "
    end)
    |> Enum.chunk_every(3)
  end

  defp hand_list(%State{my_hand: hand}), do: hand |> Enum.map(&Piece.as_emoji/1) |> Enum.sort()
end
