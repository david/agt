defmodule Agt.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Agt.AgentSupervisor, name: Agt.AgentSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Agt.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
