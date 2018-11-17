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

  @spec new(
          AnimalShogiEx.Piece.t(),
          AnimalShogiEx.Position.t(),
          :player | :opponent
        ) :: AnimalShogiEx.Fighter.t()
  def new(piece, %Position{} = position, owner)
      when Piece.is_piece(piece) and is_owner(owner),
      do: %__MODULE__{piece: piece, position: position, owner: owner}

  @spec available_moves(t) :: [Move.direction()]
  def available_moves(%Fighter{} = fighter), do: fighter.piece |> Piece.moveable_directions()

  defimpl Inspect, for: __MODULE__ do
    def inspect(%Fighter{piece: p, position: pos, owner: :player}, _),
      do: "myF!(#{Piece.friendly_name(p)} at #{Kernel.inspect(pos)})"

    def inspect(%Fighter{piece: p, position: pos, owner: :opponent}, _),
      do: "hisF!(#{Piece.friendly_name(p)} at #{Kernel.inspect(pos)})"
  end
end
