defmodule Agt.Agent do
  @moduledoc """
  AI Agent abstraction.
  """

  use GenServer

  alias Agt.Conversations
  alias Agt.GeminiClient

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
  def init(conversation_id) do
    {:ok,
     %{conversation_id: conversation_id, messages: Conversations.list_messages(conversation_id)}}
  end

  @impl true
  def handle_call(:get_conversation_id, _from, %{conversation_id: conversation_id} = state) do
    {:reply, conversation_id, state}
  end

  @impl true
  def handle_call(
        {:prompt, prompt},
        _from,
        %{conversation_id: conversation_id, messages: messages} = state
      ) do
    for part <- prompt do
      {:ok, _message} = Conversations.create_message(part, conversation_id)

      debug(part)
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
      debug(part)

      {:ok, _message} = Conversations.create_message(part, conversation_id)
    end

    {:reply, {:ok, parts}, %{state | messages: parts ++ messages}}
  end

  defp handle_response({:error, error}, state) do
    cond do
      String.match?(error, ~r/reason: :timeout/) ->
        Logger.info("Timeout")

        {:reply, {:error, :timeout}, state}

      true ->
        Logger.info("Error: #{error}")

        {:reply, {:error, error}, state}
    end
  end

  defp debug(part) do
    part |> inspect(printable_limit: 48) |> Logger.info()
  end
end
