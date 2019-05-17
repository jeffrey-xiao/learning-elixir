defmodule Pooly do
  use Application

  defmodule SampleWorker do
    use GenServer

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def init(_opts) do
      {:ok, %{}}
    end

    def handle_info(:exit, _state) do
      exit(:normal)
    end
  end

  def start(_type, _args) do
    pool_config = [mfa: {SampleWorker, :start_link, []}, size: 5]
    start_pool(pool_config)
  end

  def start_pool(pool_config) do
    Pooly.Supervisor.start_link(pool_config)
  end

  def check_out() do
    Pooly.Server.check_out()
  end

  def check_in(worker_pid) do
    Pooly.Server.check_in(worker_pid)
  end

  def status() do
    Pooly.Server.status()
  end
end
