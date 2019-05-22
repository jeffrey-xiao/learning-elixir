defmodule FortuneTest do
  use ExUnit.Case
  doctest Fortune

  test "greets the world" do
    assert Fortune.hello() == :world
  end
end
