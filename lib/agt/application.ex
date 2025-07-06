defmodule Agt.Application do
  @moduledoc false

  use Application

  alias Agt.Message.UserMessage

  @rules_path "AGENT.md"

  def start(_type, _args) do
    # TODO:Several places know about the .agt directory. This should be centralized.
    # Possibly through Agt.Storage?
    File.mkdir_p!(".agt")

    rules = read_agent_md()

    children = [
      {Agt.Agent, {generate_conversation_id(), %UserMessage{body: rules}}},
      {Agt.REPL, {%{rules: rules && @rules_path}, name: Agt.REPL}}
    ]

    opts = [strategy: :one_for_one, name: Agt.ApplicationSupervisor]

    Supervisor.start_link(children, opts)
  end

  defp generate_conversation_id do
    DateTime.utc_now() |> DateTime.to_unix() |> to_string()
  end

  defp read_agent_md do
    case File.read(@rules_path) do
      {:ok, content} ->
        content

      {:error, _reason} ->
        nil
    end
  end
end
