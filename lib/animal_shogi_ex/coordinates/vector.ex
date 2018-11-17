defmodule AnimalShogiEx.Vector do
  @moduledoc """
  The diff of two `Position`s, newer to the older.

  This helps when you want to convert valid diffs into `Move`s.
  """

  defstruct [:row, :col]

  alias AnimalShogiEx.Move

  @doc """
  Returns `{:ok, Move.direction}` if a defined move, otherwise a `{:error, :undefined_move}`.
  It is `:undefined_move` not to incorporate with `:invalid` that may be used on piece move validations.
  """
  @spec to_move(%__MODULE__{}) :: {:ok, Move.direction()} | {:error, :undefined_move}
  def to_move(%__MODULE__{col: 0, row: -1}), do: {:ok, Move.Direction.UP}
  def to_move(%__MODULE__{col: -1, row: -1}), do: {:ok, Move.Direction.UP_LEFT}
  def to_move(%__MODULE__{col: 1, row: -1}), do: {:ok, Move.Direction.UP_RIGHT}
  def to_move(%__MODULE__{col: -1, row: 0}), do: {:ok, Move.Direction.LEFT}
  def to_move(%__MODULE__{col: 1, row: 0}), do: {:ok, Move.Direction.RIGHT}
  def to_move(%__MODULE__{col: 0, row: 1}), do: {:ok, Move.Direction.DOWN}
  def to_move(%__MODULE__{col: -1, row: 1}), do: {:ok, Move.Direction.DOWN_LEFT}
  def to_move(%__MODULE__{col: 1, row: 1}), do: {:ok, Move.Direction.DOWN_RIGHT}
  def to_move(%__MODULE__{}), do: {:error, :undefined_move}
end
