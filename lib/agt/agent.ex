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
  def handle_call({:send_prompt, user_messages}, _from, state) do
    %{messages: old_messages, system_prompt: system_prompt} = state

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

  defp handle_response({:ok, model_messages, %{total_tokens: response_total_tokens}}, state) do
    %{messages: old_messages, total_tokens: current_tokens} = state

    messages = concat_messages(model_messages, old_messages)
    total_tokens = current_tokens + response_total_tokens

    {:reply, {:ok, model_messages}, %{state | messages: messages, total_tokens: total_tokens}}
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

  defp concat_messages(new_messages, old_messages),
    do: new_messages |> Enum.reverse() |> Kernel.++(old_messages)
end
