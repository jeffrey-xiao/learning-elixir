defmodule Pooly.PoolServer do
  use GenServer

  defmodule State do
    defstruct mfa: nil,
              name: nil,
              pool_sup: nil,
              monitors: nil,
              workers: nil,
              size: nil,
              overflow: nil,
              max_overflow: nil,
              waiting: nil
  end

  def start_link(pool_sup: pool_sup, pool_config: pool_config) do
    GenServer.start_link(__MODULE__, [pool_sup, pool_config], name: name(pool_config[:name]))
  end

  def check_out(pool_name, block, timeout) do
    GenServer.call(name(pool_name), {:check_out, block}, timeout)
  end

  def check_in(pool_name, worker_pid) do
    GenServer.call(name(pool_name), {:check_in, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(name(pool_name), :status)
  end

  def init([pool_sup, pool_config]) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    waiting = :queue.new()

    init(pool_config, %State{
      pool_sup: pool_sup,
      monitors: monitors,
      overflow: 0,
      waiting: waiting
    })
  end

  def init([{:size, size} | rest], state) do
    init(rest, %{state | size: size})
  end

  def init([{:mfa, mfa} | rest], state) do
    init(rest, %{state | mfa: mfa})
  end

  def init([{:name, name} | rest], state) do
    init(rest, %{state | name: name})
  end

  def init([{:max_overflow, max_overflow} | rest], state) do
    init(rest, %{state | max_overflow: max_overflow})
  end

  def init([_ | rest], state) do
    init(rest, state)
  end

  def init([], state) do
    %{name: name, size: size, mfa: mfa} = state
    workers = prepopulate(size, mfa, name)
    {:ok, %{state | workers: workers}}
  end

  def handle_call({:check_out, block}, {from_pid, _ref} = from, state) do
    %{
      workers: workers,
      monitors: monitors,
      overflow: overflow,
      max_overflow: max_overflow,
      waiting: waiting,
      mfa: mfa,
      name: name
    } = state

    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] when overflow < max_overflow ->
        ref = Process.monitor(from_pid)
        worker = new_worker(mfa, name)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | overflow: overflow + 1}}

      [] when block == true ->
        ref = Process.monitor(from_pid)
        waiting = :queue.in({from, ref}, waiting)
        {:noreply, %{state | waiting: waiting}, :infinity}

      [] ->
        {:reply, :full, state}
    end
  end

  def handle_call(
        :status,
        _from,
        %{workers: workers, monitors: monitors, overflow: overflow} = state
      ) do
    state_name =
      cond do
        length(workers) != 0 -> :ready
        overflow > 0 -> :overflow
        true -> :full
      end

    {:reply, {state_name, length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_call({:check_in, worker}, _from, %{monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = handle_check_in(worker, state)
        {:reply, :ok, new_state}

      [] ->
        {:reply, {:err, :worker_not_checked_out}, state}
    end
  end

  defp handle_check_in(pid, state) do
    %{
      workers: workers,
      monitors: monitors,
      overflow: overflow,
      waiting: waiting,
      name: name
    } = state

    case :queue.out(waiting) do
      {{:value, {from, ref}}, rest} ->
        true = :ets.insert(monitors, {pid, ref})
        GenServer.reply(from, pid)
        %{state | waiting: rest}

      {:empty, _empty} when overflow > 0 ->
        true = Process.unlink(pid)
        DynamicSupervisor.terminate_child(worker_sup_name(name), pid)
        %{state | overflow: overflow - 1}

      {:empty, _empty} ->
        %{state | workers: [pid | workers]}
    end
  end

  def handle_info({:DOWN, ref, _, _, _}, state = %{monitors: monitors, workers: workers}) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[worker_pid]] ->
        true = :ets.delete(monitors, worker_pid)
        new_state = %{state | workers: [worker_pid | workers]}
        {:noreply, new_state}

      [] ->
        {:noreply, state}
    end
  end

  def handle_info(
        {:EXIT, worker_pid, _reason},
        state = %{monitors: monitors, workers: workers, mfa: mfa, name: name}
      ) do
    case :ets.lookup(monitors, worker_pid) do
      [{worker_pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, worker_pid)
        new_state = handle_worker_exit(state)
        {:noreply, new_state}

      [] ->
        new_workers = [
          new_worker(mfa, name) | workers |> Enum.reject(fn pid -> pid == worker_pid end)
        ]

        {:noreply, %{state | workers: new_workers}}
    end
  end

  def handle_worker_exit(state) do
    %{
      workers: workers,
      monitors: monitors,
      overflow: overflow,
      waiting: waiting,
      mfa: mfa,
      name: name
    } = state

    case :queue.out(waiting) do
      {{:value, {from, ref}}, rest} ->
        new_worker = new_worker(mfa, name)
        true = :ets.insert(monitors, {new_worker, ref})
        GenServer.reply(from, new_worker)
        %{state | waiting: rest}

      {:empty, _empty} when overflow > 0 ->
        %{state | overflow: overflow - 1}

      {:empty, _empty} ->
        %{state | workers: [new_worker(mfa, name) | workers]}
    end
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp name(pool_name) do
    :"Server#{pool_name}"
  end

  defp prepopulate(size, mfa, name) do
    prepopulate(size, mfa, name, [])
  end

  defp prepopulate(size, _mfa, _name, workers) when size < 1 do
    workers
  end

  defp prepopulate(size, mfa, name, workers) do
    prepopulate(size - 1, mfa, name, [new_worker(mfa, name) | workers])
  end

  defp new_worker(mfa, pool_name) do
    {:ok, worker} = Pooly.WorkerSupervisor.start_child(mfa, pool_name)
    Process.link(worker)
    worker
  end

  defp worker_sup_name(name) do
    :"WorkerSupervisor#{name}"
  end
end
