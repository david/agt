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

    conversation = [message | messages]

    {:ok, response} =
      conversation
      |> Enum.reverse()
      |> GeminiClient.generate_content()

    {:ok, _message} = Conversations.create_message(response, conversation_id)

    {:reply, {:ok, response}, %{state | messages: [response | conversation]}}
  end
end
