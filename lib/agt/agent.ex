defmodule Agt.Agent do
  @moduledoc """
  AI Agent abstraction.
  """

  use GenServer

  alias Agt.Conversations
  alias Agt.GeminiClient
  alias Agt.Message.{FunctionCall, FunctionResponse, Prompt, Response}

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def retry(pid) do
    GenServer.call(pid, :retry, 300_000)
  end

  def prompt(%Prompt{} = prompt, pid) do
    GenServer.call(pid, {:prompt, prompt}, 300_000)
  end

  def function_result(%FunctionResponse{} = response, pid) do
    GenServer.call(
      pid,
      {:prompt, response},
      300_000
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

    log_message(message)

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
      log_message(part)

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

  defp log_message(%Prompt{body: body}) do
    Logger.info("Prompt: #{body |> String.slice(0, 30) |> inspect()}...")
  end

  defp log_message(%Response{body: body}) do
    Logger.info("Response: #{body |> String.slice(0, 30) |> inspect()}...")
  end

  defp log_message(%FunctionCall{name: name, arguments: arguments}) do
    Logger.info("FunctionCall: name=#{name} arguments=#{inspect(arguments)}")
  end

  defp log_message(%FunctionResponse{name: name, result: result}) when is_list(result) do
    Logger.info(
      "FunctionResponse: name=#{name} result=#{result |> Enum.slice(0, 3) |> inspect()}"
    )
  end

  defp log_message(%FunctionResponse{name: name, result: result}) when is_binary(result) do
    Logger.info(
      "FunctionResponse: name=#{name} result=#{result |> String.slice(0, 30) |> inspect()}"
    )
  end

  defp log_message(%FunctionResponse{name: name, result: result}) do
    Logger.info("FunctionResponse: name=#{name} result=#{inspect(result)}")
  end
end
