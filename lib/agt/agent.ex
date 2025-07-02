defmodule Agt.Agent do
  @moduledoc """
  AI Agent abstraction.
  """

  use GenServer

  alias Agt.GeminiClient
  alias Agt.Config
  alias Agt.ModelSpecification

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def retry(pid) do
    GenServer.call(pid, :retry, 300_000)
  end

  def send_prompt(prompt, pid) when is_list(prompt) do
    GenServer.call(pid, {:send_prompt, prompt}, 300_000)
  end

  def get_meta(pid) do
    GenServer.call(pid, :get_meta)
  end

  @impl true
  def init({messages, system_prompt}) do
    {:ok, model_name} = Config.get_model()

    {:ok,
     %{
       system_prompt: system_prompt,
       messages: messages,
       total_tokens: 0,
       model_name: model_name
     }}
  end

  @impl true
  def handle_call(
        {:send_prompt, prompt},
        _from,
        %{messages: messages, system_prompt: system_prompt} =
          state
      ) do
    messages = prompt ++ messages

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
         {:ok, parts, %{total_tokens: total_tokens}},
         %{messages: messages, total_tokens: current_tokens} =
           state
       ) do
    {:reply, {:ok, parts},
     %{state | messages: parts ++ messages, total_tokens: current_tokens + total_tokens}}
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
