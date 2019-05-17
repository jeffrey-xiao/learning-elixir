defmodule Weather do
  def get_temperatures(cities) do
    coordinator_pid = spawn(Weather.Coordinator, :execute, [[], Enum.count(cities)])
    cities |> Enum.each(fn city ->
      worker_pid = spawn(Weather.Worker, :execute, [])
      send(worker_pid, {coordinator_pid, city})
    end)
  end
end
