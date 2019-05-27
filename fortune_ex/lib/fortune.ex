defmodule Fortune do
  use Application
  require Logger

  def start(type, _args) do
    case type do
      :normal ->
        Logger.info("Application is started on #{node()}")

      {:takeover, old_node} ->
        Logger.info("#{node()} is taking over #{old_node}")

      {:failover, old_node} ->
        Logger.info("#{old_node} is failing over to #{node()}")
    end

    Supervisor.start_link(__MODULE__, nil, name: {:global, Fortune.Supervisor})
  end

  def fact() do
    Fortune.Server.fact()
  end

  def init(_args) do
    children = [{Fortune.Server, nil}]
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
