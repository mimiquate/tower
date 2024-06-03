defmodule TowerTest do
  use ExUnit.Case
  doctest Tower

  test "greets the world" do
    assert Tower.hello() == :world
  end
end
