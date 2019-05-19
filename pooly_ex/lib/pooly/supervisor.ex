defmodule Pooly.Supervisor do
  use Supervisor

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def init(pools_config) do
    children = [
      {Pooly.PoolsSupervisor, args: []},
      {Pooly.Server, pools_config: pools_config}
    ]

    opts = [strategy: :one_for_all]
    Supervisor.init(children, opts)
  end
end
