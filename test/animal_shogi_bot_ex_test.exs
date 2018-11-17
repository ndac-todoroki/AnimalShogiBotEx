defmodule AnimalShogiBotExTest do
  use ExUnit.Case
  doctest AnimalShogiBotEx

  test "greets the world" do
    assert AnimalShogiBotEx.hello() == :world
  end
end
