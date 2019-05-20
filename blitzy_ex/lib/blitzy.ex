defmodule Blitzy do
  use Application

  def start(_type, _args) do
    Blitzy.Supervisor.start_link()
  end
end
