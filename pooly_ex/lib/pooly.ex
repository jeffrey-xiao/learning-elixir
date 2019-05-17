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
    pools_config = [
      [name: "1", mfa: {SampleWorker, :start_link, []}, size: 3],
      [name: "2", mfa: {SampleWorker, :start_link, []}, size: 4],
      [name: "3", mfa: {SampleWorker, :start_link, []}, size: 5],
    ]
    start_pools(pools_config)
  end

  def start_pools(pools_config) do
    Pooly.Supervisor.start_link(pools_config)
  end

  def check_out(pool_name) do
    Pooly.Server.check_out(pool_name)
  end

  def check_in(pool_name, worker_pid) do
    Pooly.Server.check_in(pool_name, worker_pid)
  end

  def status(pool_name) do
    Pooly.Server.status(pool_name)
  end
end
