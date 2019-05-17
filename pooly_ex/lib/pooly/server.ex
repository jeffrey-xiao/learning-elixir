defmodule Pooly.Server do
  use GenServer
  import Supervisor.Spec

  def start_link(pool_config) do
    GenServer.start_link(__MODULE__, pool_config, name: __MODULE__)
  end

  def check_out(pool_name) do
    GenServer.call(:"Server#{pool_name}", :check_out)
  end

  def check_in(pool_name, worker_pid) do
    GenServer.cast(:"Server#{pool_name}", {:check_in, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(:"Server#{pool_name}", :status)
  end

  def init(pools_config) do
    pools_config |> Enum.each(fn(pool_config) ->
      send(self(), {:start_pool, pool_config})
    end)
    {:ok, pools_config}
  end

  def handle_info({:start_pool, pool_config}, state) do
    {:ok, _pool_sup} = Supervisor.start_child(Pooly.PoolsSupervisor, supervisor_spec(pool_config))
    {:noreply, state}
  end

  defp supervisor_spec(pool_config) do
    opts = [id: :"Supervisor#{pool_config[:name]}"]
    supervisor(Pooly.PoolSupervisor, [pool_config], opts)
  end
end
