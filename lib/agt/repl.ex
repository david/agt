defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """
  use GenServer

  alias Agt.Agent
  alias Agt.Config
  alias Agt.REPL.MarkdownRenderer
  alias Agt.Message.FunctionCall
  alias Agt.Message.FunctionResponse
  alias Agt.Message.ModelMessage
  alias Agt.Message.UserMessage
  alias Agt.REPL.Editor
  alias Agt.Tools

  def start_link({args, opts}) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @impl true
  def init(opts) do
    case Config.get_api_key() do
      {:ok, _api_key} ->
        display_startup_message(opts)

        send(self(), :prompt)

        {:ok, %{}}

      {:error, error} ->
        IO.puts("Error: #{error}")
        IO.puts("Please set the GEMINI_API_KEY environment variable")

        {:stop, error}
    end
  end

  @impl true
  def handle_info(:prompt, state) do
    agent_meta = Agent.get_meta()

    case Editor.read(agent_meta) do
      :ignore ->
        send(self(), :prompt)

      prompt ->
        handle_input(prompt, self())
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:agent_update, %ModelMessage{body: body}}, state) do
    (IO.ANSI.clear_line() <> "\r" <> MarkdownRenderer.render(body)) |> IO.puts()

    {:noreply, state}
  end

  @impl true
  def handle_info({:agent_update, :function_calls_begin}, state) do
    (IO.ANSI.clear_line() <> "\r") |> IO.write()

    {:noreply, state}
  end

  @impl true
  def handle_info({:agent_update, :function_calls_end}, state) do
    IO.write("\n...")

    {:noreply, state}
  end

  @impl true
  def handle_info({:agent_update, %FunctionCall{} = function_call}, state) do
    ("* " <> tool_name(function_call) <> "(" <> tool_arguments(function_call) <> ")")
    |> IO.write()

    {:noreply, state}
  end

  @impl true
  def handle_info({:agent_update, %FunctionResponse{result: %{output: _}}}, state) do
    ("\r" <> IO.ANSI.light_green() <> "" <> IO.ANSI.white() <> "\n") |> IO.write()

    {:noreply, state}
  end

  @impl true
  def handle_info({:agent_update, %FunctionResponse{result: %{error: _}}}, state) do
    ("\r" <> IO.ANSI.light_red() <> "" <> IO.ANSI.white() <> "\n") |> IO.write()

    {:noreply, state}
  end

  @impl true
  def handle_info(:agent_done, state) do
    send(self(), :prompt)

    {:noreply, state}
  end

  @impl true
  def handle_info({:agent_error, :timeout}, state) do
    IO.puts("Request timed out.")
    send(self(), :prompt)
    {:noreply, state}
  end

  @impl true
  def handle_info({:agent_error, reason}, state) do
    IO.puts("An error occurred: #{inspect(reason)}")
    send(self(), :prompt)
    {:noreply, state}
  end

  defp tool_name(%FunctionCall{name: name}), do: IO.ANSI.magenta() <> name <> IO.ANSI.white()

  defp tool_arguments(%FunctionCall{name: name, arguments: args}) do
    args
    |> Enum.filter(fn {key, _value} -> key in Tools.get_visible_properties(name) end)
    |> Enum.map(&tool_key_value(&1))
    |> Enum.join(" ")
  end

  defp tool_key_value({key, value}) do
    IO.ANSI.cyan() <>
      to_string(key) <>
      IO.ANSI.white() <> "=" <> IO.ANSI.light_white() <> inspect(value) <> IO.ANSI.white()
  end

  defp handle_input("/role " <> role_name, _repl_pid) do
    role_name = String.trim(role_name)

    {:ok, _} = load_role(role_name)

    # case load_role(role_name) do
    #   {:ok, _} ->
    #     IO.puts("Successfully loaded role: #{role_name}")
    #
    #   {:error, {:not_found, role_name}} ->
    #     IO.puts("Error: Role not found: #{role_name}")
    # end
  end

  defp handle_input(input, repl_pid) do
    IO.write("\n...")

    send_messages(input, repl_pid)
  end

  defp display_startup_message(%{rules: nil}), do: IO.puts("Rules not loaded")
  defp display_startup_message(%{rules: rules}), do: IO.puts("Rules loaded from #{rules}")

  defp send_messages(input, repl_pid) do
    [%UserMessage{body: input}]
    |> Agent.send_messages(repl_pid)
  end

  defp load_role(name) do
    {:ok, _prompt} = load_prompt("prompts/#{name}.md")

    # Agent.reset(prompt)

    {:ok, nil}
  end

  defp load_prompt(path) do
    case File.read(path) do
      {:error, :enoent} ->
        {:error, {:not_found, path}}

      {:error, reason} ->
        {:error, reason}

      response ->
        response
    end
  end
end
