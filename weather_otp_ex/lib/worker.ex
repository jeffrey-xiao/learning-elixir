defmodule WeatherOtp.Worker do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_temperature(pid, location) do
    GenServer.call(pid, {:location, location})
  end

  def get_stats(pid) do
    GenServer.call(pid, :stats)
  end

  def reset_stats(pid) do
    GenServer.cast(pid, :reset_stats)
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def terminate(reason, stats) do
    IO.puts("Server terminated because of #{inspect(reason)}")
    inspect(stats)
    :ok
  end

  def handle_call({:location, location}, _from, stats) do
    case get_url(location) |> HTTPoison.get() |> parse_response do
      {:ok, temp} ->
        new_stats =
          case Map.has_key?(stats, location) do
            true -> Map.update!(stats, location, &(&1 + 1))
            false -> Map.put_new(stats, location, 1)
          end
        {:reply, "#{temp}°C", new_stats}

      _ ->
        {:reply, :error, stats}
    end
  end

  def handle_call(:stats, _from, stats) do
    {:reply, stats, stats}
  end

  def handle_cast(:reset_stats, _stats) do
    {:noreply, %{}}
  end

  def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode!() |> compute_temperature
  end

  defp parse_response(_), do: :error

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp get_url(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey()}"
  end

  defp apikey do
    "fc3cf768e2ea4f683adac8f074a036c6"
  end
end
