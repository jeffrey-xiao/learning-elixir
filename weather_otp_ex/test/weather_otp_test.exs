defmodule WeatherOtpTest do
  use ExUnit.Case
  doctest WeatherOtp

  test "greets the world" do
    assert WeatherOtp.hello() == :world
  end
end
