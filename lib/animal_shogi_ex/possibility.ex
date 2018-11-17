defmodule AnimalShogiEx.Possibility do
  alias AnimalShogiEx.{Fighter, Game, Fighter, Move}
  alias Game.State, as: GameState

  alias __MODULE__, as: Possibility

  require Move

  defstruct [:fighter, :direction, :target]

  @type t :: %Possibility{
          fighter: Fighter.t(),
          direction: Move.direction(),
          target: Fighter | nil
        }

  @spec new({Fighter.t(), Move.direction(), Fighter.t() | :none}) :: t
  def new({%Fighter{} = fighter, direction, :none})
      when Move.is_direction(direction),
      do: %__MODULE__{fighter: fighter, direction: direction, target: nil}

  def new({%Fighter{} = fighter, direction, %Fighter{} = target})
      when Move.is_direction(direction),
      do: %__MODULE__{fighter: fighter, direction: direction, target: target}

  @spec new(Fighter.t(), Move.direction(), Fighter.t() | :none) :: t
  def new(%Fighter{} = fighter, direction, :none)
      when Move.is_direction(direction),
      do: %__MODULE__{fighter: fighter, direction: direction, target: nil}

  def new(%Fighter{} = fighter, direction, %Fighter{} = target)
      when Move.is_direction(direction),
      do: %__MODULE__{fighter: fighter, direction: direction, target: target}

  @doc """
  ### Examples
      iex> state
      ...> |> Game.State.available_moves
      ...> |> Possibility.sort(ASC)
      myF!(Lion at <2, d>)    UP_RIGHT nil
      myF!(Lion at <2, d>)    UP_LEFT  nil
      myF!(Zo at <1, d>)      UP_LEFT  nil
      myF!(Kirin at <3, d>)   UP       nil
      myF!(Hiyoko at <2, c>)  UP       hisF!(Hiyoko at <2, b>)
      myF!(Hiyoko at <1, b>)  UP       hisF!(Kirin at <1, a>)
  """
  def sort(possibilities, ASC) when is_list(possibilities),
    do: possibilities |> Enum.sort(&Possibility.Sorter.asc/2)

  def sort(possibilities, DESC) when is_list(possibilities),
    do: possibilities |> Enum.sort(&Possibility.Sorter.desc/2)
end

defprotocol AnimalShogiEx.Possibility.Sorter do
  @fallback_to_any true

  @spec asc(Sorter.t(), any) :: boolean
  def asc(elem1, elem2)

  @spec desc(Sorter.t(), any) :: boolean
  def desc(elem1, elem2)
end

defimpl AnimalShogiEx.Possibility.Sorter, for: AnimalShogiEx.Possibility do
  alias AnimalShogiEx.Possibility.Sorter

  @spec asc(any(), any) :: boolean
  def asc(%{fighter: f1, target: t1}, %{fighter: f2, target: t2})
      when t1 == t2,
      do: Sorter.asc(f1, f2)

  def asc(%{target: t1}, %{target: t2}), do: Sorter.desc(t1, t2)

  @spec desc(any(), any) :: boolean
  def desc(%{fighter: f1, target: t1}, %{fighter: f2, target: t2})
      when t1 == t2,
      do: Sorter.desc(f1, f2)

  def desc(%{target: t1}, %{target: t2}), do: Sorter.asc(t1, t2)
end

defimpl AnimalShogiEx.Possibility.Sorter, for: Any do
  @spec asc(any(), any) :: boolean
  def asc(elem1, elem2), do: elem1 >= elem2

  @spec desc(any(), any) :: boolean
  def desc(elem1, elem2), do: elem1 <= elem2
end
