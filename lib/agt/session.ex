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

  def start_link({args, opts}) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get_meta do
    GenServer.call(__MODULE__, :get_meta)
  end

  def send_messages(messages) do
    GenServer.call(__MODULE__, {:send_messages, messages}, 300_000)
  end

  def reset(system_prompt) do
    GenServer.call(__MODULE__, {:reset, system_prompt})
  end

  # GenServer Callbacks

  @impl true
  def init({conversation_id, rules}) do
    # TODO: Add a default system prompt when none is provided?
    reset_agent(rules || "", conversation_id)

    {:ok,
     %{
       conversation_id: conversation_id,
       rules: rules,
       system_prompt: nil
     }}
  end

  @impl true
  def handle_call(:get_meta, _from, %{conversation_id: conversation_id} = state) do
    [{agent, _}] = Registry.lookup(Agt.AgentRegistry, conversation_id)

    {:reply, Agent.get_meta(agent), state}
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
end
