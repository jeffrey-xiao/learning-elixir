defmodule Weather.Worker do
  def execute() do
    receive do
      {sender_pid, location} ->
        send(sender_pid, get_temperature(location))
      msg ->
        IO.puts("Invalid message: #{msg}")
    end
    execute()
  end

  def get_temperature(location) do
    result = get_url(location) |> HTTPoison.get |> parse_response
    case result do
      {:ok, temp} -> {:ok, "#{location}: #{temp}°C"}
      :error -> {:error, "#{location}: N/A"}
    end
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode! |> compute_temperature
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
