defmodule AnimalShogiEx.Position do
  @moduledoc """
  Represents `Fighter`'s positions on the Shogi board.
  The player's side is always down.

           "1" "2" "3"
          +---+---+---+
      "a" |   |   |   | 0
          +---+---+---+
      "b" |   |   |   | 1
          +---+---+---+
      "c" |   |   |   | 2
          +---+---+---+
      "d" |   |   |   | 3
          +---+---+---+
            0   1   2

  The Left and Top letters are what they are described in the game,
  the right and bottom letters are integers which are used to present them in this struct.

  Thus, the position `"2c"` in the game will be represented `%Position{column: 1, row: 2}`

  """

  alias __MODULE__, as: Position
  alias AnimalShogiEx.Vector

  @row_size 4 - 1
  @col_size 3 - 1

  @row_signs ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
  @col_signs ~w(1 2 3 4 5 6 7 8 9)

  defstruct ~w[row column]a

  @type t :: %Position{row: integer, column: integer}

  @type as_str :: String.t()

  defimpl Inspect, for: __MODULE__ do
    def inspect(position, _) do
      "<#{Position.col_string(position)}, #{Position.row_string(position)}>"
    end
  end

  @doc """
  Creates a new `Position` struct by parsing the position string, or, by giving the exact indexes.
  Currently the board size is **#{@row_size}x#{@col_size}**. If the request exceeds that, it will return an `:out_of_bounds` error.

  ## Example

      iex> {:ok, pos} = Position.new("a", "3")
      {:ok, %Position{column: 2, row: 0}}

  """
  @spec new(integer, integer) :: {:ok, AnimalShogiEx.Position.t()} | {:error, :out_of_bounds}
  @spec new(String.t()) :: {:ok, AnimalShogiEx.Position.t()} | {:error, :out_of_bounds}
  @spec new(String.t(), String.t()) ::
          {:ok, AnimalShogiEx.Position.t()} | {:error, :out_of_bounds}

  def new(<<col::bytes-size(1)>> <> <<row::bytes-size(1)>>)
      when row in @row_signs and col in @col_signs,
      do: new(col, row)

  def new(<<col::bytes-size(1)>>, <<row::bytes-size(1)>>)
      when row in @row_signs and col in @col_signs do
    col_index = @col_signs |> Enum.find_index(&(&1 == col))
    row_index = @row_signs |> Enum.find_index(&(&1 == row))

    new(col_index, row_index)
  end

  def new(col, row) when row <= @row_size and col <= @col_size,
    do: {:ok, %Position{column: col, row: row}}

  def new(col, row) when row > @row_size or col > @col_size, do: {:error, :out_of_bounds}

  @doc """
  Converts position into a string.

  ### Example

      iex> position = Position.new(0, 0)
      iex> position |> Position.to_string()
      "1a"

  """
  @spec to_string(Position.t()) :: String.t()
  def to_string(%__MODULE__{} = position),
    do: col_string(position) <> row_string(position)

  @spec row_string(AnimalShogiEx.Position.t()) :: any()
  def row_string(%__MODULE__{row: row}), do: Enum.at(@row_signs, row)
  def col_string(%__MODULE__{column: col}), do: Enum.at(@col_signs, col)

  @doc """
  Gives the position seen from the opposite sight, say from the Opponent side.

  ## Example

      iex> {:ok, pos} = Position.new("a", "3")
      {:ok, %Position{column: 2, row: 0}}

      iex> pos |> Position.opponent_view
      %Position{column: 1, row: 4}

  """
  @spec inverse(Position.t()) :: Position.t()
  def inverse(%__MODULE__{row: my_row, column: my_col}),
    do: %Position{row: @row_size - my_row, column: @col_size - my_col}

  @spec diff(Position.t(), Position.t()) :: AnimalShogiEx.Vector.t()
  def diff(%__MODULE__{} = from, %__MODULE__{} = to),
    do: %Vector{row: to.row - from.row, col: to.column - from.column}

  def add(%__MODULE__{column: c, row: r}, %Vector{col: dc, row: dr}),
    do: new(c + dc, r + dr)
end

defimpl String.Chars, for: AnimalShogiEx.Position do
  def to_string(position), do: AnimalShogiEx.Position.to_string(position)
end

defimpl AnimalShogiEx.Possibility.Sorter, for: AnimalShogiEx.Position do
  @spec asc(any(), any) :: boolean
  def asc(%{row: r1, col: c1}, %{row: r2, col: c2}) when r1 == r2, do: c1 <= c2
  def asc(%{row: r1}, %{row: r2}), do: r1 <= r2

  @spec desc(any(), any) :: boolean
  def desc(%{row: r1, col: c1}, %{row: r2, col: c2}) when r1 == r2, do: c1 >= c2
  def desc(%{row: r1}, %{row: r2}), do: r1 >= r2
end
