defmodule Pooly do
  use Application

  @timeout 5000

  def start(_type, _args) do
    start_pools(Application.get_env(:pooly, :pools_config, []))
  end

  def start_pools(pools_config) do
    Pooly.Supervisor.start_link(pools_config)
  end

  def check_out(pool_name, block \\ false, timeout \\ @timeout) do
    Pooly.Server.check_out(pool_name, block, timeout)
  end

  def check_in(pool_name, worker_pid) do
    Pooly.Server.check_in(pool_name, worker_pid)
  end

  def status(pool_name) do
    Pooly.Server.status(pool_name)
  end
end
