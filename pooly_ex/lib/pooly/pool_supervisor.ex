defmodule Pooly.PoolSupervisor do
  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config, name: :"PoolSupervisor#{pool_config[:name]}")
  end

  def init(pool_config) do
    {:ok, mfa} = Keyword.fetch(pool_config, :mfa)
    {:ok, name} = Keyword.fetch(pool_config, :name)
    sup_opts = [restart: :temporary]
    children = [
      supervisor(Pooly.WorkerSupervisor, [mfa, name], sup_opts),
      worker(Pooly.PoolServer, [self(), pool_config]),
    ]
    opts = [strategy: :one_for_all]
    supervise(children, opts)
  end
end
