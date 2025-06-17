defmodule Agt.AgentSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_agent() do
    DateTime.utc_now() |> DateTime.to_unix() |> to_string() |> start_agent()
  end

  def start_agent(conversation_id) do
    spec = {Agt.Agent, conversation_id}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
