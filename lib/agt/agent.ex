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

  def send_messages(messages) when is_list(messages) do
    GenServer.call(__MODULE__, {:send_messages, messages}, 300_000)
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
  def handle_call({:send_messages, user_messages}, _from, state) do
    %{conversation_id: conversation_id, messages: old_messages, system_prompt: system_prompt} =
      state

    for part <- user_messages,
        do: {:ok, _message} = Conversations.create_message(part, conversation_id)

    messages = concat_messages(user_messages, old_messages)

    messages
    |> Enum.reverse()
    |> GeminiClient.generate_content(system_prompt)
    |> handle_response(%{state | messages: messages})
  end

  @impl true
  def handle_call(:retry, _from, %{messages: messages, system_prompt: system_prompt} = state) do
    messages
    |> Enum.reverse()
    |> GeminiClient.generate_content(system_prompt)
    |> handle_response(state)
  end

  @impl true
  def handle_call(:get_meta, _from, %{total_tokens: count, model_name: model} = state) do
    {:reply,
     model
     |> ModelSpecification.get_spec()
     |> Map.merge(%{total_tokens: count, model_name: model}), state}
  end

  defp handle_response(
         {:ok, model_messages, %{total_tokens: response_total_tokens}},
         state
       ) do
    %{conversation_id: conversation_id, messages: old_messages, total_tokens: current_tokens} =
      state

    for part <- model_messages,
        do: {:ok, _message} = Conversations.create_message(part, conversation_id)

    messages = concat_messages(model_messages, old_messages)
    total_tokens = current_tokens + response_total_tokens
    new_state = %{state | messages: messages, total_tokens: total_tokens}

    function_calls = Enum.filter(model_messages, &match?(%FunctionCall{}, &1))

    if Enum.any?(function_calls) do
      handle_function_calls(function_calls, new_state)
    else
      model_parts = Enum.filter(model_messages, &match?(%ModelMessage{}, &1))
      {:reply, {:ok, model_parts}, new_state}
    end
  end

  defp handle_response({:error, error}, state) do
    cond do
      String.match?(error, ~r/reason: :timeout/) ->
        Logger.error("Timeout")

        {:reply, {:error, :timeout}, state}

      true ->
        Logger.error("Error: #{error}")

        {:reply, {:error, error}, state}
    end
  end

  defp handle_function_calls(function_calls, state) do
    %{conversation_id: conversation_id, messages: old_messages, system_prompt: system_prompt} =
      state

    results =
      for %{name: name, arguments: args} <- function_calls do
        %FunctionResponse{name: name, result: Tools.call(name, args)}
      end

    for part <- results, do: {:ok, _} = Conversations.create_message(part, conversation_id)

    messages = concat_messages(results, old_messages)

    messages
    |> Enum.reverse()
    |> GeminiClient.generate_content(system_prompt)
    |> handle_response(%{state | messages: messages})
  end

  defp concat_messages(new_messages, old_messages),
    do: new_messages |> Enum.reverse() |> Kernel.++(old_messages)
end
