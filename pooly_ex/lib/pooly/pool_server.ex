defmodule Pooly.PoolServer do
  use GenServer
  import Supervisor.Spec

  defmodule State do
    defstruct pool_sup: nil, size: nil, mfa: nil, monitors: nil, worker_sup: nil, workers: nil, name: nil
  end

  def start_link(pool_sup, pool_config) do
    GenServer.start_link(__MODULE__, [pool_sup, pool_config], name: name(pool_config[:name]))
  end

  def check_out(pool_name) do
    GenServer.call(name(pool_name), :check_out)
  end

  def check_in(pool_name, worker_pid) do
    GenServer.cast(name(pool_name), {:check_in, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(name(pool_name), :status)
  end

  def init([pool_sup, pool_config]) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{pool_sup: pool_sup, monitors: monitors})
  end

  def init([{:mfa, mfa} | rest], state) do
    init(rest, %{state | mfa: mfa})
  end

  def init([{:size, size} | rest], state) do
    init(rest, %{state | size: size})
  end

  def init([{:name, name} | rest], state) do
    init(rest, %{state | name: name})
  end

  def init([_ | rest], state) do
    init(rest, state)
  end

  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def handle_call(:check_out, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(:status, _from, %{workers: workers, monitors: monitors} = state) do
    {:reply, {length(workers), :ets.info(monitors, :size), state}}
  end

  def handle_cast({:check_in, worker}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid | workers]}}

      [] ->
        {:noreply, state}
    end
  end

  def handle_info(:start_worker_supervisor, state = %{pool_sup: pool_sup, size: size, mfa: mfa, name: name}) do
    {:ok, worker_sup} = Supervisor.start_child(pool_sup, worker_sup_spec(name, mfa))
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  def handle_info({:DOWN, ref, _, _, _}, state = %{monitors: monitors, workers: workers}) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid | workers]}}

      [[]] ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, worker_sup, reason}, state = %{worker_sup: worker_sup}) do
    {:stop, reason, state}
  end

  def handle_info(
        {:EXIT, pid, _reason},
        state = %{monitors: monitors, workers: workers, worker_sup: worker_sup}
      ) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [new_worker(worker_sup) | workers]}}

      [] ->
        {:noreply, %{state | workers: [new_worker(worker_sup) | workers]}}
    end
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp name(pool_name) do
    :"Server#{pool_name}"
  end

  defp worker_sup_spec(name, mfa) do
    opts = [restart: :temporary, id: :"WorkerSupervisor#{name}"]
    supervisor(Pooly.WorkerSupervisor, [self(), mfa], opts)
  end

  defp prepopulate(size, worker_sup) do
    prepopulate(size, worker_sup, [])
  end

  defp prepopulate(size, _workers_sup, workers) when size < 1 do
    workers
  end

  defp prepopulate(size, workers_sup, workers) do
    prepopulate(size - 1, workers_sup, [new_worker(workers_sup) | workers])
  end

  defp new_worker(worker_sup) do
    {:ok, worker} = Supervisor.start_child(worker_sup, [[]])
    Process.link(worker)
    worker
  end
end