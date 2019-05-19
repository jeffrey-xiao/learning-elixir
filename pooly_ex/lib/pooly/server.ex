defmodule Pooly.Server do
  use GenServer

  def start_link(pools_config: pools_config) do
    GenServer.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def check_out(pool_name, block, timeout) do
    Pooly.PoolServer.check_out(pool_name, block, timeout)
  end

  def check_in(pool_name, worker_pid) do
    Pooly.PoolServer.check_in(pool_name, worker_pid)
  end

  def status(pool_name) do
    Pooly.PoolServer.status(pool_name)
  end

  def init(pools_config) do
    pools_config |> Enum.each(fn(pool_config) ->
      {:ok, _pid} = Pooly.PoolsSupervisor.start_child(pool_config)
    end)
    {:ok, pools_config}
  end
end
