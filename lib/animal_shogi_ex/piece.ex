defmodule AnimalShogiEx.Piece do
  @moduledoc """
  Module to check whether the `Piece` type can move or not.
  """

  alias __MODULE__, as: Piece
  alias AnimalShogiEx.Move
  alias Piece.{Hiyoko, Kirin, Zo, Niwatori, Lion}
  require Move

  @piece_types [Hiyoko, Kirin, Lion, Niwatori, Zo]
  @type type :: Hiyoko | Kirin | Lion | Niwatori | Zo

  defstruct [:type]
  @type t :: %Piece{type: type()}

  defguard is_type(piece_type) when piece_type in @piece_types

  @doc """
  Return a sigil representing the Piece.
  """
  @callback sigil :: String.t()

  @callback moveable_directions :: [Move.direction()]

  @spec new(Piece.type()) :: Piece.t()
  def new(type) when is_type(type), do: %Piece{type: type}

  @doc """
  ## Example

      iex> alias AnimalShogiEx.{Piece, Move}
      iex> piyo = Piece.new(Piece.Hiyoko)
      iex> piyo |> Piece.moveable?(Move.Direction.UP)
      true
      iex> piyo |> Piece.moveable?(Move.Direction.DOWN)
      false

  """
  @spec moveable?(AnimalShogiEx.Piece.t(), AnimalShogiEx.Move.direction()) :: boolean
  def moveable?(%Piece{type: type}, direction)
      when is_type(type) and Move.is_direction(direction),
      do: type.moveable?(direction)

  @spec as_sigil(AnimalShogiEx.Piece.t()) :: String.t()
  def as_sigil(%Piece{type: type}) when is_type(type), do: type.sigil()

  def friendly_name(%Piece{type: type}) when is_type(type),
    do: type |> to_string() |> String.split(".") |> List.last()

  @spec from_type(<<_::8>>) :: Piece.t()
  def from_type("h"), do: %Piece{type: Hiyoko}
  def from_type("k"), do: %Piece{type: Kirin}
  def from_type("z"), do: %Piece{type: Zo}

  @spec moveable_directions(Piece.t()) :: [Move.direction()]
  def moveable_directions(%Piece{type: type}) when is_type(type), do: type.moveable_directions

  @spec moveable_directions(Piece.type()) :: [Move.direction()]
  def moveable_directions(type) when is_type(type), do: type.moveable_directions
end

defimpl AnimalShogiEx.Possibility.Sorter, for: AnimalShogiEx.Piece do
  alias AnimalShogiEx.Piece
  alias Piece.{Hiyoko, Kirin, Zo, Niwatori, Lion}

  require Piece

  # to order by types
  @piece_types %{
    Hiyoko => 10,
    Kirin => 20,
    Zo => 30,
    Niwatori => 40,
    Lion => 100
  }

  @spec asc(any(), any) :: boolean
  def asc(%{type: type1}, %{type: type2}) when Piece.is_type(type1) and Piece.is_type(type2),
    do: @piece_types[type1] >= @piece_types[type2]

  @spec desc(any(), any) :: boolean
  def desc(%{type: type1}, %{type: type2}) when Piece.is_type(type1) and Piece.is_type(type2),
    do: @piece_types[type1] <= @piece_types[type2]
end
