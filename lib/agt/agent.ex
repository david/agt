defmodule Agt.Agent do
  @moduledoc """
  AI Agent abstraction.
  """

  use GenServer

  alias Agt.Conversations
  alias Agt.GeminiClient
  alias Agt.Operator

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def prompt(pid, message) do
    GenServer.call(pid, {:prompt, message}, 120_000)
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
    {:ok, message} =
      %Operator.Message{body: prompt}
      |> Conversations.create_message(conversation_id)

    conversation = [message | messages]

    {:ok, response} =
      conversation
      |> Enum.reverse()
      |> GeminiClient.generate_content()

    {:ok, _message} = Conversations.create_message(response, conversation_id)

    {:reply, {:ok, response.body}, %{state | messages: [response | conversation]}}
  end
end
