defmodule Weather.Coordinator do
  def execute(results \\ [], total_results) do
    receive do
      {_, result} ->
        new_results = [result | results]

        if total_results == Enum.count(new_results) do
          send(self(), :exit)
        end

        execute(new_results, total_results)

      :exit ->
        IO.puts(results |> Enum.sort() |> Enum.join("\n"))

      _ ->
        execute(results, total_results)
    end
  end
end
