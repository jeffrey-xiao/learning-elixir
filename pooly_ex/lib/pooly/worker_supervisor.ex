defmodule Pooly.WorkerSupervisor do
  use Supervisor

  def start_link({_, _, _} = mfa, name) do
    Supervisor.start_link(__MODULE__, mfa, name: :"WorkerSupervisor#{name}")
  end

  def init({module, func, args}) do
    worker_opts = [restart: :temporary,
                   shutdown: 5000,
                   function: func]
    children = [worker(module, args, worker_opts)]
    opts = [strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 5]
    supervise(children, opts)
  end
end
