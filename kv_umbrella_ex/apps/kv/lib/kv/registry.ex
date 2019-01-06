defmodule Kv.Registry do
  use GenServer

  @doc """
  Starts the registry with the given options.

  `:name` is required.
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Looks up the bucket PID for `name` in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  @doc """
  Stops the registry
  """
  def stop(server) do
    GenServer.stop(server)
  end

  def init(name) do
    {:ok, {:ets.new(name, [:named_table, read_concurrency: true]), %{}}}
  end

  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, bucket} ->
        {:reply, bucket, {names, refs}}

      :error ->
        {:ok, bucket} = DynamicSupervisor.start_child(Kv.BucketSupervisor, Kv.Bucket)
        :ets.insert(names, {name, bucket})
        {:reply, bucket, {names, Map.put(refs, Process.monitor(bucket), name)}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end
end
