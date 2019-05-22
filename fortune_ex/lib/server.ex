defmodule Fortune.Server do
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
  end

  def fact() do
    GenServer.call({:global, __MODULE__}, :fact)
  end

  def init([]) do
    :random.seed(:os.timestamp())
    fortunes = "data/fortune.txt"
               |> File.read!()
               |> String.split("\n%\n")
    {:ok, fortunes}
  end

  def handle_call(:fact, _from, fortunes) do
    fortune = fortunes
              |> Enum.shuffle()
              |> List.first()
    {:reply, fortune, fortunes}
  end
end
