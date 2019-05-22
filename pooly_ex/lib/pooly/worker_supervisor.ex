defmodule Pooly.WorkerSupervisor do
  use DynamicSupervisor

  def name(pool_name) do
    :"WorkerSupervisor#{pool_name}"
  end

  def start_link(pool_config) do
    {:ok, pool_name} = Keyword.fetch(pool_config, :name)
    DynamicSupervisor.start_link(__MODULE__, [], name: name(pool_name))
  end

  def start_child({module, func, args}, pool_name) do
    child_spec = %{id: :"#{module}", start: {module, func, args}, restart: :temporary}
    DynamicSupervisor.start_child(name(pool_name), child_spec)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
