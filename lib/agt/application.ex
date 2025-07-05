defmodule Agt.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # TODO:Several places know about the .agt directory. This should be centralized.
    # Possibly through Agt.Storage?
    File.mkdir_p!(".agt")

    children = [
      {Registry, keys: :unique, name: Agt.AgentRegistry},
      {Agt.AgentSupervisor, name: Agt.AgentSupervisor},
      {Agt.Session, {generate_conversation_id(), name: Agt.Session}},
      {Agt.REPL, name: Agt.REPL}
    ]

    opts = [strategy: :one_for_one, name: Agt.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp generate_conversation_id do
    DateTime.utc_now() |> DateTime.to_unix() |> to_string()
  end
end
