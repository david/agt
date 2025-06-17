defmodule Agt.Conversation do
  @moduledoc """
  Conversation between the user and the AI.
  """

  use GenServer

  alias Agt.GeminiClient
  alias Agt.GeminiClient.Operator

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def prompt(message) do
    GenServer.call(__MODULE__, {:prompt, message}, 120_000)
  end

  @impl true
  def init(_opts) do
    {:ok, []}
  end

  @impl true
  def handle_call({:prompt, message}, _from, conversation) do
    conversation = [%Operator.Message{body: message} | conversation]

    {:ok, response} =
      conversation
      |> Enum.reverse()
      |> GeminiClient.generate_content()

    {:reply, {:ok, response.body}, [response | conversation]}
  end
end
