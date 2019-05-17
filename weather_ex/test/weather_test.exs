defmodule WeatherExTest do
  use ExUnit.Case
  doctest WeatherEx

  test "greets the world" do
    assert WeatherEx.hello() == :world
  end
end
