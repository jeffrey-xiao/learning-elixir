defmodule Blitzy.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_args) do
    children = [{Task.Supervisor, name: Blitzy.TasksSupervisor}]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_task(node, module, func, args) do
    Task.Supervisor.async({Blitzy.TasksSupervisor, node}, module, func, args)
  end
end
