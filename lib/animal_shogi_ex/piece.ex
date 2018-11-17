defmodule AnimalShogiEx.Piece do
  @moduledoc """
  Module to check whether the `Piece` type can move or not.
  """

  alias __MODULE__, as: Piece
  alias AnimalShogiEx.Move
  require Move

  @piece_types [Piece.Hiyoko, Piece.Kirin, Piece.Lion, Piece.Niwatori, Piece.Zo]

  @type t :: Piece.Hiyoko | Piece.Kirin | Piece.Lion | Piece.Niwatori | Piece.Zo

  defguard is_piece(piece) when piece in @piece_types

  @doc """
  Return a sigil representing the Piece.
  """
  @callback sigil :: String.t()

  @callback moveable_directions :: [Move.direction()]

  @doc """
  ## Example

      iex> alias AnimalShogiEx.Piece
      iex> Piece.Hiyoko |> Piece.moveable?(Move.Direction.UP)
      true
      iex> Piece.Hiyoko |> Piece.moveable?(Move.Direction.DOWN)
      false

  """
  @spec moveable?(AnimalShogiEx.Piece.t(), AnimalShogiEx.Move.direction()) :: boolean
  def moveable?(piece, direction)
      when is_piece(piece) and Move.is_direction(direction),
      do: piece.moveable?(direction)

  @spec as_sigil(AnimalShogiEx.Piece.t()) :: String.t()
  def as_sigil(piece) when is_piece(piece), do: piece.sigil()

  def friendly_name(piece) when is_piece(piece),
    do: piece |> to_string() |> String.split(".") |> List.last()

  @spec from_type(<<_::8>>) :: Piece.t()
  def from_type(type)
  def from_type("h"), do: Piece.Hiyoko
  def from_type("k"), do: Piece.Kirin
  def from_type("z"), do: Piece.Zo

  @spec moveable_directions(Piece.t()) :: [Move.direction()]
  def moveable_directions(piece) when is_piece(piece), do: piece.moveable_directions
end

### This is needed in case if you changed Pieces into Structs, instead of just being modules and atoms.
#
# defprotocol AnimalShogiEx.Piece do
#   @doc """
#       iex> piyo = Piece.Hiyoko.new()
#       iex> piyo |> AnimalShogiEx.Piece.moveable?(Direction.UP)
#       true
#   """
#   @spec moveable?(AnimalShogiEx.t(), AnimalShogiEx.Move.direction()) :: boolean
#   def moveable?(piece, direction)
# end
#
# defmodule AnimalShogiEx.Piece.Implement do
#   alias AnimalShogiEx.Piece
#
#   defmacro __using__(_) do
#     quote do
#       defimpl unquote(Piece), for: __MODULE__ do
#         def moveable?(%me{}, direction), do: me.moveable?(direction)
#       end
#     end
#   end
# end
