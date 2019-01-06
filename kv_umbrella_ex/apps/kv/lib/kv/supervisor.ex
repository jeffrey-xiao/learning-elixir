defmodule Kv.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Kv.Registry, name: Kv.Registry},
      {DynamicSupervisor, name: Kv.BucketSupervisor, strategy: :one_for_one},
      {Task.Supervisor, name: Kv.RouterTasks}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
