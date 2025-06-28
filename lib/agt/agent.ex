defmodule Agt.Agent do
  @moduledoc """
  AI Agent abstraction.
  """

  use GenServer

  alias Agt.Conversations
  alias Agt.GeminiClient
  alias Agt.Message.Prompt

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def get_conversation_id(pid) do
    GenServer.call(pid, :get_conversation_id)
  end

  def retry(pid) do
    GenServer.call(pid, :retry, 300_000)
  end

  def prompt(prompt, pid) when is_list(prompt) do
    GenServer.call(pid, {:prompt, prompt}, 300_000)
  end

  @impl true
  def init({conversation_id, rules}) do
    messages =
      case {Conversations.list_messages(conversation_id), rules} do
        {[], r} when not is_nil(r) ->
          [%Prompt{body: r, role: "user"}]

        {messages, _} ->
          messages
      end

    {:ok,
     %{
       conversation_id: conversation_id,
       messages: messages
     }}
  end

  @impl true
  def handle_call(:get_conversation_id, _from, %{conversation_id: conversation_id} = state) do
    {:reply, conversation_id, state}
  end

  @impl true
  def handle_call(
        {:prompt, prompt},
        _from,
        %{conversation_id: conversation_id, messages: messages} =
          state
      ) do
    for part <- prompt do
      {:ok, _message} = Conversations.create_message(part, conversation_id)
    end

    messages = prompt ++ messages

    messages
    |> Enum.reverse()
    |> GeminiClient.generate_content()
    |> handle_response(%{state | messages: messages})
  end

  @impl true
  def handle_call(:retry, _from, %{messages: messages} = state) do
    messages
    |> Enum.reverse()
    |> GeminiClient.generate_content()
    |> handle_response(state)
  end

  defp handle_response(
         {:ok, parts},
         %{conversation_id: conversation_id, messages: messages} = state
       ) do
    # FIXME: Should be transactional (?)
    for part <- parts do
      # FIXME: DRY: Should be part of the main flow (handle_call(...))
      {:ok, _message} = Conversations.create_message(part, conversation_id)
    end

    {:reply, {:ok, parts}, %{state | messages: parts ++ messages}}
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
end
