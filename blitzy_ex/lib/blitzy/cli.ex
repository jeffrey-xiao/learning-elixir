use Mix.Config

defmodule Blitzy.CLI do
  require Logger

  def main(args) do
    {:ok, _pid} = Application.get_env(:blitzy, :master_node) |> Node.start()

    Application.get_env(:blitzy, :slave_nodes)
    |> Enum.each(fn node -> true = Node.connect(node) end)

    args
    |> parse_args()
    |> process_options([node() | Node.list()])
  end

  defp parse_args(args) do
    OptionParser.parse(args, aliases: [n: :requests], strict: [requests: :integer])
  end

  defp process_options(options, nodes) do
    case options do
      {[requests: requests], [url], []} ->
        send_requests(requests, url, nodes)

      _ ->
        show_help()
    end
  end

  defp send_requests(requests, url, nodes) do
    Logger.info("Sending #{requests} requests to #{url}")

    total_nodes = Enum.count(nodes)
    requests_per_node = div(requests, total_nodes)
    remainder = rem(requests, total_nodes)

    nodes
    |> Enum.with_index()
    |> Enum.map(fn {node, index} ->
      node_requests = requests_per_node + if remainder <= index, do: 1, else: 0

      1..node_requests
      |> Enum.map(fn _ ->
        Blitzy.Supervisor.start_task(node, Blitzy.Worker, :start, [url])
      end)
    end)
    |> Enum.flat_map(fn tasks -> tasks end)
    |> Enum.map(fn task -> Task.await(task, :infinity) end)
    |> parse_results
  end

  defp parse_results(results) do
    {successes, _failures} =
      results
      |> Enum.split_with(fn result ->
        case result do
          {:ok, _} -> true
          _ -> false
        end
      end)

    total_workers = Enum.count(results)
    total_successes = Enum.count(successes)
    total_failures = total_workers - total_successes

    times = successes |> Enum.map(fn {:ok, time} -> time end)
    average_time = Enum.sum(times) / total_successes
    longest_time = Enum.max(times)
    shortest_time = Enum.min(times)

    IO.puts("""
      Total workers: #{total_workers}
      Successfuly requests: #{total_successes}
      Failed requests: #{total_failures}
      Average (ms): #{average_time}
      Longest (ms): #{longest_time}
      Shortest (ms): #{shortest_time}
    """)
  end

  defp show_help() do
    IO.puts("""
      Usage:
      blitz -n [requests] [url]

      Options
      -n, --requests    Number of requests

      Example
      ./blitzy -n 100 https://www.google.com/
    """)

    System.halt(0)
  end
end
