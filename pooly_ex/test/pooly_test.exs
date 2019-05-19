defmodule PoolyTest do
  use ExUnit.Case
  doctest Pooly

  defmodule SampleWorker do
    use GenServer

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def work(pid, duration) do
      GenServer.cast(pid, {:work, duration})
    end

    def init(_opts) do
      {:ok, %{}}
    end

    def handle_cast({:work, duration}, state) do
      :timer.sleep(duration)
      {:stop, :normal, state}
    end

    def handle_info(:exit, _state) do
      exit(:normal)
    end
  end

  setup do
    Application.stop(:pooly)
    pools_config = [
      [name: "1", mfa: {SampleWorker, :start_link, []}, size: 2, max_overflow: 1],
      [name: "2", mfa: {SampleWorker, :start_link, []}, size: 2, max_overflow: 0],
      [name: "3", mfa: {SampleWorker, :start_link, []}, size: 2, max_overflow: 0],
    ]
    Application.put_env(:pooly, :pools_config, pools_config)
    :ok = Application.start(:pooly)
  end

  test "status" do
    require IEx
    IEx.pry
    assert Pooly.status("1") == {:ready, 2, 0}
    w1 = Pooly.check_out("1")
    w2 = Pooly.check_out("1")
    assert Pooly.status("1") == {:full, 0, 2}
    w3 = Pooly.check_out("1")
    assert Pooly.status("1") == {:overflow, 0, 3}
    Pooly.check_in("1", w3)
    assert Pooly.status("1") == {:full, 0, 2}
    Pooly.check_in("1", w2)
    Pooly.check_in("1", w1)
    assert Pooly.status("1") == {:ready, 2, 0}
  end

  test "blocking checkout" do
    w1 = Pooly.check_out("2")
    w2 = Pooly.check_out("2")
    SampleWorker.work(w1, 1000)
    assert Pooly.status("2") == {:full, 0, 2}
    w3 = Pooly.check_out("2", true, :infinity)
    Pooly.check_out("2", w2)
    Pooly.check_out("2", w3)
  end

  test "full checkout" do
    Pooly.check_out("2")
    Pooly.check_out("2")
    :full = Pooly.check_out("2")
  end
end
