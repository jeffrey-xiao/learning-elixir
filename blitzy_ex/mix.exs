defmodule Blitzy.MixProject do
  use Mix.Project

  def project do
    [
      app: :blitzy,
      version: "0.1.0",
      elixir: "~> 1.8",
      escript: [main_module: Blitzy.CLI],
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Blitzy, []},
      extra_applications: [:logger, :httpoison, :timex]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.9.0"},
      {:timex, "~> 3.0"},
      {:tzdata, "~> 0.1.8", override: true}
    ]
  end
end
