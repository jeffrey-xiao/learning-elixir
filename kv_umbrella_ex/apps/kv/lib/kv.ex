defmodule Kv do
  use Application

  def start(_type, _args) do
    Kv.Supervisor.start_link(name: Kv.Supervisor)
  end
end
