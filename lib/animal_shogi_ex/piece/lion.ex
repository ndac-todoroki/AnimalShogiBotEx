defmodule AnimalShogiEx.Piece.Lion do
  alias AnimalShogiEx.Piece

  alias AnimalShogiEx.Move

  alias Move.Direction.{
    UP,
    DOWN,
    LEFT,
    RIGHT,
    UP_RIGHT,
    UP_LEFT,
    DOWN_RIGHT,
    DOWN_LEFT
  }

  @moveable_directions [UP, DOWN, LEFT, RIGHT, UP_RIGHT, UP_LEFT, DOWN_RIGHT, DOWN_LEFT]

  @behaviour Move
  @behaviour Piece

  @impl Move
  @spec moveable?(Piece.direction()) :: boolean
  def moveable?(direction) when direction in @moveable_directions, do: true
  def moveable?(_), do: false

  @impl Piece
  def moveable_directions, do: @moveable_directions

  @impl Piece
  def sigil, do: "l"
end
