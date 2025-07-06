defmodule Agt.Agent do
  @moduledoc """
  AI Agent abstraction.
  """

  use GenServer

  alias Agt.Config
  alias Agt.Conversations
  alias Agt.GeminiClient
  alias Agt.ModelSpecification
  alias Agt.Message.FunctionCall
  alias Agt.Message.FunctionResponse
  alias Agt.Message.ModelMessage
  alias Agt.Tools

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def restart() do
    Supervisor.restart_child(Agt.ApplicationSupervisor, __MODULE__)
  end

  def retry() do
    GenServer.call(__MODULE__, :retry, 300_000)
  end

  def send_messages(messages, origin) do
    GenServer.cast(__MODULE__, {:send_messages, messages, origin})
  end

  def get_meta() do
    GenServer.call(__MODULE__, :get_meta)
  end

  @impl true
  def init({conversation_id, system_prompt}) do
    {:ok, model_name} = Config.get_model()

    {:ok,
     %{
       system_prompt: system_prompt,
       conversation_id: conversation_id,
       messages: Conversations.list_messages(conversation_id),
       total_tokens: 0,
       model_name: model_name
     }}
  end

  @impl true
  def handle_cast({:send_messages, user_messages, origin}, state) do
    send_messages_local(user_messages, origin, state)
  end

  @impl true
  def handle_call(:retry, _from, %{messages: messages, system_prompt: system_prompt} = state) do
    messages
    |> Enum.reverse()
    |> GeminiClient.generate_content(system_prompt)
    # TODO: This needs a origin to work correctly in the new async model.
    # For now, it will likely fail or not behave as expected.
    |> handle_response(state, self())
  end

  @impl true
  def handle_call(:get_meta, _from, %{total_tokens: count, model_name: model} = state) do
    {:reply,
     model
     |> ModelSpecification.get_spec()
     |> Map.merge(%{total_tokens: count, model_name: model}), state}
  end

  defp handle_response({:ok, messages, meta}, state, origin) do
    %{conversation_id: conversation_id, messages: old_messages, total_tokens: current_tokens} =
      state

    messages
    |> Enum.map(&normalize/1)
    |> Enum.each(&({:ok, _msg} = Conversations.create_message(&1, conversation_id)))

    messages
    |> Enum.filter(&match?(%ModelMessage{}, &1))
    |> Enum.each(&send(origin, {:agent_update, &1}))

    function_calls = Enum.filter(messages, &match?(%FunctionCall{}, &1))

    Enum.each(function_calls, &send(origin, {:agent_update, &1}))

    function_responses =
      function_calls
      |> Enum.map(fn %FunctionCall{name: name, arguments: args} ->
        %FunctionResponse{name: name, result: Tools.call(name, args)}
      end)

    Enum.each(function_responses, &send(origin, {:agent_update, &1}))

    %{total_tokens: response_total_tokens} = meta

    new_state = %{
      state
      | messages: concat_messages(messages, old_messages),
        total_tokens: current_tokens + response_total_tokens
    }

    if Enum.any?(function_responses) do
      send_messages_local(function_responses, origin, new_state)
    else
      send(origin, :agent_done)

      {:noreply, new_state}
    end
  end

  defp handle_response({:error, error}, state, origin) do
    # Asynchronously notify the REPL of the error.
    send(origin, {:agent_error, error})

    cond do
      String.match?(error, ~r/reason: :timeout/) ->
        Logger.error("Timeout")
        {:noreply, state}

      true ->
        Logger.error("Error: #{error}")
        {:noreply, state}
    end
  end

  defp normalize(%ModelMessage{body: body}), do: %ModelMessage{body: String.trim(body)}
  defp normalize(function_call), do: function_call

  defp concat_messages(new_messages, old_messages),
    do: new_messages |> Enum.reverse() |> Kernel.++(old_messages)

  defp send_messages_local(user_messages, origin, state) do
    %{conversation_id: conversation_id, messages: old_messages, system_prompt: system_prompt} =
      state

    for part <- user_messages,
        do: {:ok, _message} = Conversations.create_message(part, conversation_id)

    messages = concat_messages(user_messages, old_messages)

    messages
    |> Enum.reverse()
    |> GeminiClient.generate_content(system_prompt)
    |> handle_response(%{state | messages: messages}, origin)
  end
end
