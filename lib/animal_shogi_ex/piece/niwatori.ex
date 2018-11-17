defmodule AnimalShogiEx.Piece.Niwatori do
  alias AnimalShogiEx.Piece

  alias AnimalShogiEx.Move

  alias Move.Direction.{
    UP,
    DOWN,
    LEFT,
    RIGHT,
    UP_RIGHT,
    UP_LEFT
  }

  @moveable_directions [UP, DOWN, LEFT, RIGHT, UP_RIGHT, UP_LEFT]

  @behaviour Move
  @behaviour Piece

  @impl Move
  @spec moveable?(Piece.direction()) :: boolean
  def moveable?(direction) when direction in @moveable_directions, do: true
  def moveable?(_), do: false

  @impl Piece
  @spec moveable_directions :: [Move.direction()]
  def moveable_directions, do: @moveable_directions

  @impl Piece
  def sigil, do: "n"
end
