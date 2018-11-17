defmodule AnimalShogiEx.Fighter do
  @moduledoc """
  An `AnimalShogiEx.Piece` with a `AnimalShogiEx.Position`. = An `AnimalShogiEx.Fighter`.
  """

  alias __MODULE__, as: Fighter
  alias AnimalShogiEx.{Piece, Position, Move}

  require Piece
  require Move

  defstruct [:piece, :position, :owner]

  @type t :: %Fighter{piece: Piece.t(), position: Position.t(), owner: :player | :opponent}

  defguard is_owner(owner) when owner in ~w(player opponent)a

  @spec new(Piece.t() | Piece.type(), Position.t(), :player | :opponent) :: Fighter.t()
  def new(%Piece{} = piece, %Position{} = position, owner)
      when is_owner(owner),
      do: %__MODULE__{piece: piece, position: position, owner: owner}

  def new(piece_type, %Position{} = position, owner)
      when Piece.is_type(piece_type) and is_owner(owner),
      do: %__MODULE__{piece: Piece.new(piece_type), position: position, owner: owner}

  @spec available_moves(t) :: [Move.direction()]
  def available_moves(%Fighter{} = fighter), do: fighter.piece |> Piece.moveable_directions()

  defimpl Inspect, for: __MODULE__ do
    def inspect(%Fighter{piece: p, position: pos, owner: :player}, _),
      do: "myF!(#{Piece.friendly_name(p)} at #{Kernel.inspect(pos)})"

    def inspect(%Fighter{piece: p, position: pos, owner: :opponent}, _),
      do: "hisF!(#{Piece.friendly_name(p)} at #{Kernel.inspect(pos)})"
  end
end

defimpl AnimalShogiEx.Possibility.Sorter, for: AnimalShogiEx.Fighter do
  alias AnimalShogiEx.Possibility.Sorter

  @spec asc(any(), any) :: boolean
  def asc(%{piece: p1, position: pos1, owner: o1}, %{piece: p2, position: pos2, owner: o2})
      when p1 == p2 and o1 == o2,
      do: Sorter.asc(pos1, pos2)

  def asc(%{piece: p1, owner: o1}, %{piece: p2, owner: o2})
      when o1 == o2,
      do: Sorter.asc(p1, p2)

  def asc(%{owner: :opponent}, %{owner: :player}), do: false
  def asc(%{owner: :player}, %{owner: :opponent}), do: true
  def asc(_fighter, _), do: true

  @spec desc(any(), any) :: boolean
  def desc(%{piece: p1, position: pos1, owner: o1}, %{piece: p2, position: pos2, owner: o2})
      when p1 == p2 and o1 == o2,
      do: Sorter.desc(pos1, pos2)

  def desc(%{piece: p1, owner: o1}, %{piece: p2, owner: o2})
      when o1 == o2,
      do: Sorter.desc(p1, p2)

  def desc(%{owner: :opponent}, %{owner: :player}), do: true
  def desc(%{owner: :player}, %{owner: :opponent}), do: false
  def desc(_fighter, _), do: false
end
