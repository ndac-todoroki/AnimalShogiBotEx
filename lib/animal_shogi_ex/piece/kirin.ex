defmodule AnimalShogiEx.Piece.Kirin do
  alias AnimalShogiEx.Piece

  alias AnimalShogiEx.Move

  alias Move.Direction.{
    UP,
    DOWN,
    LEFT,
    RIGHT
  }

  @moveable_directions [UP, DOWN, LEFT, RIGHT]

  @behaviour Move
  @behaviour Piece

  @impl Move
  @spec moveable?(Piece.direction()) :: boolean
  def moveable?(direction) when direction in @moveable_directions, do: true
  def moveable?(_), do: false

  @impl Piece
  def moveable_directions, do: @moveable_directions

  @impl Piece
  def sigil, do: "k"
end
