defmodule Pooly.Server do
  use GenServer
  import Supervisor.Spec

  def start_link(pool_config) do
    GenServer.start_link(__MODULE__, pool_config, name: __MODULE__)
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
      {:ok, _pid} = Supervisor.start_child(Pooly.PoolsSupervisor, supervisor_spec(pool_config))
    end)
    {:ok, pools_config}
  end

  defp supervisor_spec(pool_config) do
    opts = [id: :"Supervisor#{pool_config[:name]}"]
    supervisor(Pooly.PoolSupervisor, [pool_config], opts)
  end
end
