defmodule AnimalShogiBotEx.Server do
  alias AnimalShogiEx.Game
  alias AnimalShogiEx.Game.State, as: GameState
  alias AnimalShogiEx.{Possibility, Position}

  use GenServer

  require Integer

  def start(), do: GenServer.start_link(__MODULE__, [])

  @impl GenServer
  def init(_) do
    me = self()
    {:ok, game} = Game.start_link(me)
    {:ok, %{game: game}}
  end

  @impl GenServer
  def handle_info({Game.Server, :new_state, %GameState{} = game_state}, %{game: game} = state) do
    my_turn? = if Integer.is_odd(game_state.turn) == game_state.first?, do: true, else: false

    if my_turn? do
      %Possibility{fighter: fighter, target: _, direction: direction} =
        game_state
        |> GameState.available_moves()
        |> Possibility.sort(DESC)
        |> List.first()

      # |> IO.inspect()

      Game.move(game, fighter.position |> Position.to_string(), direction)

      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({Game.Server, :game_over, %GameState{} = game_state, result}, state) do
    # IO.puts("Gameover. You #{result}")
    # IO.inspect(game_state)
    {:noreply, state}
  end

  def handle_info({Game.Server, :error, %GameState{} = game_state}, state) do
    IO.puts("** An Error Occurred. **")
    IO.inspect(game_state)
    {:noreply, state}
  end
end
