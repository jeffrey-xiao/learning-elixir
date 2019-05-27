defmodule Pooly.PoolsSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(pool_config) do
    child_spec = {Pooly.PoolSupervisor, pool_config}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
