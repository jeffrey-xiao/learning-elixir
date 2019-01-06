defmodule KvServer.Command do
  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples
      iex> KvServer.Command.parse("CREATE shopping\r\n")
      {:ok, {:create, "shopping"}}

      iex> KvServer.Command.parse("CREATE  shopping  \r\n")
      {:ok, {:create, "shopping"}}

      iex> KvServer.Command.parse("PUT shopping milk 1\r\n")
      {:ok, {:put, "shopping", "milk", "1"}}

      iex> KvServer.Command.parse("GET shopping milk\r\n")
      {:ok, {:get, "shopping", "milk"}}

      iex> KvServer.Command.parse("DELETE shopping eggs\r\n")
      {:ok, {:delete, "shopping", "eggs"}}

  Unknown commands or commands with the wrong number of arguments return an error:

      iex> KvServer.Command.parse("UNKNOWN shopping eggs\r\n")
      {:error, :unknown_command}

      iex> KvServer.Command.parse("GET shopping\r\n")
      {:error, :unknown_command}

  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unknown_command}
    end
  end

  def run(command) do
    case command do
      {:create, bucket} ->
        Kv.Router.route(bucket, Kv.Registry, :create, [Kv.Registry, bucket])
        {:ok, "OK\r\n"}

      {:get, bucket, key} ->
        lookup(bucket, fn pid ->
          value = Kv.Router.route(bucket, Kv.Bucket, :get, [pid, key])
          {:ok, "#{value}\r\nOK\r\n"}
        end)

      {:put, bucket, key, value} ->
        lookup(bucket, fn pid ->
          Kv.Router.route(bucket, Kv.Bucket, :put, [pid, key, value])
          {:ok, "OK\r\n"}
        end)

      {:delete, bucket, key} ->
        lookup(bucket, fn pid ->
          Kv.Router.route(bucket, Kv.Bucket, :delete, [pid, key])
          {:ok, "OK\r\n"}
        end)
    end
  end

  defp lookup(bucket, callback) do
    case Kv.Router.route(bucket, Kv.Registry, :lookup, [Kv.Registry, bucket]) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, :not_found}
    end
  end
end
