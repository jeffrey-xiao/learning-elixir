defmodule Fortune.Server do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: {:global, __MODULE__})
  end

  def fact() do
    GenServer.call({:global, __MODULE__}, :fact)
  end

  def init(_args) do
    :random.seed(:os.timestamp())

    fortunes =
      "data/fortune.txt"
      |> File.read!()
      |> String.split("\n%\n")

    {:ok, fortunes}
  end

  def handle_call(:fact, _from, fortunes) do
    fortune =
      fortunes
      |> Enum.shuffle()
      |> List.first()

    {:reply, fortune, fortunes}
  end
end
