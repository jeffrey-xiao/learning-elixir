defmodule KvServer do
  require Logger

  @doc """
  Starts accepting conections on `port`.
  """
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(KvServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    msg =
      with {:ok, data} <- read_line(socket),
           {:ok, command} <- KvServer.Command.parse(data),
           do: KvServer.Command.run(command)

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, msg) do
    case msg do
      {:ok, text} ->
        :gen_tcp.send(socket, text)

      {:error, :unknown_command} ->
        :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")

      {:error, :not_found} ->
        :gen_tcp.send(socket, "BUCKET NOT FOUND\r\n")

      {:error, :closed} ->
        exit(:shutdown)

      {:error, error} ->
        :gen_tcp.send(socket, "ERROR\r\n")
        exit(error)
    end
  end
end
