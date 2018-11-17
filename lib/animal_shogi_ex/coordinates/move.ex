defmodule AnimalShogiEx.Move do
  alias __MODULE__, as: Move
  alias AnimalShogiEx.Vector

  @type direction ::
          Move.Direction.UP
          | Move.Direction.DOWN
          | Move.Direction.LEFT
          | Move.Direction.RIGHT
          | Move.Direction.UP_RIGHT
          | Move.Direction.UP_LEFT
          | Move.Direction.DOWN_RIGHT
          | Move.Direction.DOWN_LEFT

  defguard is_direction(direction)
           when direction in [
                  Move.Direction.UP,
                  Move.Direction.DOWN,
                  Move.Direction.LEFT,
                  Move.Direction.RIGHT,
                  Move.Direction.UP_RIGHT,
                  Move.Direction.UP_LEFT,
                  Move.Direction.DOWN_RIGHT,
                  Move.Direction.DOWN_LEFT
                ]

  @callback moveable?(Move.Direction.UP) :: boolean
  @callback moveable?(Move.Direction.DOWN) :: boolean
  @callback moveable?(Move.Direction.LEFT) :: boolean
  @callback moveable?(Move.Direction.RIGHT) :: boolean
  @callback moveable?(Move.Direction.UP_RIGHT) :: boolean
  @callback moveable?(Move.Direction.UP_LEFT) :: boolean
  @callback moveable?(Move.Direction.DOWN_RIGHT) :: boolean
  @callback moveable?(Move.Direction.DOWN_LEFT) :: boolean

  def to_vector(Move.Direction.UP), do: %Vector{col: 0, row: -1}
  def to_vector(Move.Direction.DOWN), do: %Vector{col: 0, row: 1}
  def to_vector(Move.Direction.LEFT), do: %Vector{col: -1, row: 0}
  def to_vector(Move.Direction.RIGHT), do: %Vector{col: 1, row: 0}
  def to_vector(Move.Direction.UP_RIGHT), do: %Vector{col: 1, row: -1}
  def to_vector(Move.Direction.UP_LEFT), do: %Vector{col: -1, row: -1}
  def to_vector(Move.Direction.DOWN_RIGHT), do: %Vector{col: 1, row: 1}
  def to_vector(Move.Direction.DOWN_LEFT), do: %Vector{col: -1, row: 1}

  def friendly_name(direction) when is_direction(direction),
    do: direction |> to_string() |> String.split(".") |> List.last()
end
