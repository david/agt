defmodule Agt.Session do
  @moduledoc """
  A GenServer responsible for managing a single session, including its state
  and the child `Agent` process.
  """

  use GenServer

  alias Agt.Agent
  alias Agt.AgentSupervisor
  alias Agt.Session.Marker

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_startup_status do
    GenServer.call(__MODULE__, :get_startup_status)
  end

  def prompt(messages) do
    GenServer.call(__MODULE__, {:prompt, messages}, 300_000)
  end

  # GenServer Callbacks

  @impl true
  def init(_) do
    # TODO:Several places know about the .agt directory. This should be centralized.
    # Possibly through Agt.Storage?
    File.mkdir_p!(".agt")

    crashed_conversation_id = Marker.read()

    conversation_id =
      crashed_conversation_id ||
        DateTime.utc_now() |> DateTime.to_unix() |> to_string()

    rules = read_agent_md()
    {:ok, agent} = AgentSupervisor.start_agent(conversation_id, rules)

    {agent, startup_status} =
      if crashed_conversation_id do
        {agent,
         %{
           session: :resumed,
           rules: rules && "AGENT.md"
         }}
      else
        {agent,
         %{
           session: :new,
           rules: rules && "AGENT.md"
         }}
      end

    agent |> Agent.get_conversation_id() |> Marker.create()

    {:ok, %{agent: agent, startup_status: startup_status}}
  end

  @impl true
  def handle_call(:get_startup_status, _from, state) do
    {:reply, state.startup_status, state}
  end

  def handle_call({:prompt, parts}, _from, %{agent: agent} = state) do
    response = Agent.prompt(parts, agent)

    {:reply, response, state}
  end

  @impl true
  def terminate(reason, _state) when reason in [:normal, :shutdown] do
    Marker.delete()
  end

  @impl true
  def terminate(_reason, _state) do
    nil
  end

  defp read_agent_md do
    case File.read("AGENT.md") do
      {:ok, content} ->
        content

      {:error, _reason} ->
        nil
    end
  end
end
