defmodule Pooly.WorkerSupervisor do
  use Supervisor

  def start_link(pool_server, {_, _, _} = mfa) do
    Supervisor.start_link(__MODULE__, [pool_server, mfa])
  end

  def init([pool_server, {module, func, args}]) do
    Process.link(pool_server)
    worker_opts = [function: func, shutdown: 5000, restart: :temporary]
    children = [worker(module, args, worker_opts)]
    opts = [strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 5]
    supervise(children, opts)
  end
end
