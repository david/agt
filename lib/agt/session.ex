defmodule Agt.Session do
  @moduledoc """
  A GenServer responsible for managing a single session, including its state
  and the child `Agent` process.
  """

  use GenServer

  alias Agt.Agent
  alias Agt.AgentSupervisor
  alias Agt.Message.UserMessage
  alias Agt.Session.Marker

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

  def send_prompt(messages) do
    GenServer.call(__MODULE__, {:send_prompt, messages}, 300_000)
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

    crashed_conversation_id = Marker.read()
    rules = read_agent_md()

    # TODO: Add a default system prompt when none is provided
    {:ok, agent} = reset_agent(rules || "", crashed_conversation_id)

    {:ok,
     %{
       agent: agent,
       rules: rules,
       startup_status: %{
         session: if(crashed_conversation_id, do: :resumed, else: :new),
         rules: rules && "AGENT.md"
       },
       system_prompt: nil
     }}
  end

  @impl true
  def handle_call(:get_meta, _from, %{agent: agent} = state) do
    {:reply, Agent.get_meta(agent), state}
  end

  @impl true
  def handle_call(:get_startup_status, _from, state) do
    {:reply, state.startup_status, state}
  end

  def handle_call({:send_prompt, parts}, _from, %{agent: agent} = state) do
    response = Agent.send_prompt(parts, agent)

    {:reply, response, state}
  end

  def handle_call(
        {:reset, system_prompt},
        _from,
        %{agent: old_agent, rules: rules} = state
      ) do
    GenServer.stop(old_agent)

    {:ok, new_agent} = reset_agent("#{system_prompt}\n\n#{rules}")

    {:reply, {:ok, new_agent}, %{state | system_prompt: system_prompt, agent: new_agent}}
  end

  defp reset_agent(system_prompt, conversation_id \\ nil) do
    conversation_id
    |> then(&(&1 || DateTime.utc_now() |> DateTime.to_unix() |> to_string()))
    |> Marker.create()
    |> AgentSupervisor.start_agent(%UserMessage{body: system_prompt})
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
