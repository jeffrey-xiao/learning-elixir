defmodule KvServer.Application do
  use Application

  def start(_type, _args) do
    port = Application.fetch_env!(:kv_server, :port)

    children = [
      {Task.Supervisor, name: KvServer.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> KvServer.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: KvServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
