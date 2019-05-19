defmodule Pooly.PoolSupervisor do
  use Supervisor

  def start_link(pool_config: pool_config) do
    Supervisor.start_link(__MODULE__, pool_config, name: :"PoolSupervisor#{pool_config[:name]}")
  end

  def init(pool_config) do
    children = [
      {Pooly.WorkerSupervisor, pool_config: pool_config},
      {Pooly.PoolServer, pool_sup: self(), pool_config: pool_config},
    ]
    opts = [strategy: :one_for_all]
    Supervisor.init(children, opts)
  end
end
