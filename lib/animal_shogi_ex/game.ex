defmodule AnimalShogiEx.Game do
  @moduledoc """
  ### Do
      iex> alias AnimalShogiEx.Game
      iex> alias AnimalShogiEx.Move.Direction.{UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT}
  """

  alias __MODULE__, as: Game
  alias AnimalShogiEx.{Position, Piece, Move}

  alias AnimalShogiEx.Move.Direction.{
    UP,
    DOWN,
    LEFT,
    RIGHT,
    UP_LEFT,
    UP_RIGHT,
    DOWN_LEFT,
    DOWN_RIGHT
  }

  @directions ~w(Elixir.UP Elixir.DOWN Elixir.LEFT Elixir.RIGHT Elixir.UPLEFT Elixir.UPRIGHT Elixir.DOWNLEFT Elixir.DOWNRIGHT)a
  @direction_map @directions
                 |> Enum.zip([UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT])
                 |> Enum.into(%{})

  require Piece
  require Move

  def child_spec(_) do
    Supervisor.Spec.worker(__MODULE__, [])
  end

  def start, do: start_link()
  def start_link, do: Game.Server.start_link([])

  def accept(game), do: GenServer.cast(game, :accept)

  @spec move(pid(), <<_::16>>, atom) :: any()
  def move(game, from_string, direction) when direction in @directions do
    with {:ok, from_position} <- Position.new(from_string) do
      GenServer.call(game, {:move, {from_position, Map.fetch!(@direction_map, direction)}})
    else
      err -> err
    end
  end

  @spec move(pid(), <<_::16>>, <<_::16>>) :: any()
  def move(game, from_string, to_string) when is_binary(from_string) and is_binary(to_string) do
    with {:ok, from_position} <- Position.new(from_string),
         {:ok, to_position} <- Position.new(to_string) do
      GenServer.call(game, {:move, {from_position, to_position}})
    else
      err -> err
    end
  end

  @spec move(pid(), <<_::16>>, <<_::16>>, boolean) :: any()
  def move(game, from_string, to_string, promotion) when is_boolean(promotion) do
    with {:ok, from_position} <- Position.new(from_string),
         {:ok, to_position} <- Position.new(to_string) do
      GenServer.call(game, {:move, {from_position, to_position}, promotion})
    else
      err -> err
    end
  end

  @spec move(pid(), <<_::16>>, Move.direction(), boolean) :: any()
  def move(game, from_string, direction, promotion)
      when Move.is_direction(direction) and is_boolean(promotion) do
    with {:ok, from_position} <- Position.new(from_string) do
      GenServer.call(game, {:move, {from_position, direction}, promotion})
    else
      err -> err
    end
  end

  @spec drop(pid(), Piece.t(), <<_::16>>) :: any()
  def drop(game, piece, to_string) when Piece.is_piece(piece) do
    with {:ok, position} <- Position.new(to_string) do
      GenServer.call(game, {:drop, {piece, position}})
    else
      err -> err
    end
  end
end
