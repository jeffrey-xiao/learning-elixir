defmodule Blitzy.Worker do
  use Timex
  require Logger

  def start(url) do
    {timestamp, response} = Duration.measure(fn -> HTTPoison.get(url) end)
    handle_response({Duration.to_milliseconds(timestamp), response})
  end

  defp handle_response({ms, {:ok, %HTTPoison.Response{status_code: code}}})
       when code >= 200 and code <= 304 do
    Logger.info("Worker [#{node()}-#{inspect(self())}] completed in #{ms} ms")
    {:ok, ms}
  end

  defp handle_response({ms, {:error, reason}}) do
    Logger.info(
      "Worker [#{node()}-#{inspect(self())}] error due to #{inspect(reason)} in #{ms} ms"
    )

    {:error, reason}
  end

  defp handle_response({ms, _}) do
    Logger.info("Worker [#{node()}-#{inspect(self())}] errored out in #{ms} ms")
    {:error, :unknown}
  end
end
