defmodule Agt.Agent do
  @moduledoc """
  AI Agent abstraction.
  """

  use GenServer

  alias Agt.Conversations
  alias Agt.GeminiClient
  alias Agt.Message.{Prompt, FunctionResponse}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def retry(pid) do
    GenServer.call(pid, :retry, 120_000)
  end

  def prompt(pid, message) do
    GenServer.call(pid, {:prompt, %Prompt{body: message}}, 120_000)
  end

  def function_result(result, name, pid) do
    GenServer.call(
      pid,
      {:prompt, %FunctionResponse{name: name, result: result}},
      120_000
    )
  end

  @impl true
  def init(conversation_id) do
    {:ok, %{conversation_id: conversation_id, messages: []}}
  end

  @impl true
  def handle_call(
        {:prompt, prompt},
        _from,
        %{conversation_id: conversation_id, messages: messages} = state
      ) do
    {:ok, message} = Conversations.create_message(prompt, conversation_id)

    messages = [message | messages]

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

  defp handle_response({:error, error}, state) do
    cond do
      String.match?(error, ~r/reason: :timeout/) ->
        {:reply, {:error, :timeout}, state}

      true ->
        {:reply, {:error, error}, state}
    end
  end

  defp handle_response(
         {:ok, response},
         %{conversation_id: conversation_id, messages: messages} = state
       ) do
    {:ok, _message} = Conversations.create_message(response, conversation_id)

    {:reply, {:ok, response}, %{state | messages: [response | messages]}}
  end
end
