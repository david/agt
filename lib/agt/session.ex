defmodule Agt.Session do
  @moduledoc """
  A GenServer responsible for managing a single session, including its state
  and the child `Agent` process.
  """

  use GenServer

  alias Agt.Agent
  alias Agt.AgentSupervisor
  alias Agt.Message.UserMessage

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_meta do
    GenServer.call(__MODULE__, :get_meta)
  end

  def get_startup_status do
    GenServer.call(__MODULE__, :get_startup_status)
  end

  def send_messages(messages) do
    GenServer.call(__MODULE__, {:send_messages, messages}, 300_000)
  end

  def reset(system_prompt) do
    GenServer.call(__MODULE__, {:reset, system_prompt})
  end

  # GenServer Callbacks

  @impl true
  def init(_) do
    # TODO:Several places know about the .agt directory. This should be centralized.
    # Possibly through Agt.Storage?
    File.mkdir_p!(".agt")

    conversation_id = get_conversation_id()
    rules = read_agent_md()

    # TODO: Add a default system prompt when none is provided?
    reset_agent(rules || "", conversation_id)

    {:ok,
     %{
       conversation_id: conversation_id,
       rules: rules,
       startup_status: %{
         rules: rules && "AGENT.md"
       },
       system_prompt: nil
     }}
  end

  @impl true
  def handle_call(:get_meta, _from, %{conversation_id: conversation_id} = state) do
    [{agent, _}] = Registry.lookup(Agt.AgentRegistry, conversation_id)

    {:reply, Agent.get_meta(agent), state}
  end

  @impl true
  def handle_call(:get_startup_status, _from, state) do
    {:reply, state.startup_status, state}
  end

  def handle_call({:send_messages, user_messages}, _from, state) do
    %{conversation_id: conversation_id} = state

    [{agent, _}] = Registry.lookup(Agt.AgentRegistry, conversation_id)

    case Agent.send_messages(user_messages, agent) do
      {:ok, model_messages} ->
        {:reply, {:ok, model_messages}, state}

      {:error, :timeout} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:reset, system_prompt}, _from, state) do
    %{conversation_id: conversation_id} = state

    [{old_agent, _}] = Registry.lookup(Agt.AgentRegistry, conversation_id)

    GenServer.stop(old_agent)

    {:reply, {:ok, nil}, %{state | system_prompt: system_prompt}}
  end

  defp reset_agent(system_prompt, conversation_id) do
    {:ok, _pid} = AgentSupervisor.start_agent(conversation_id, %UserMessage{body: system_prompt})
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

  defp get_conversation_id() do
    DateTime.utc_now() |> DateTime.to_unix() |> to_string()
  end
end
