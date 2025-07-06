defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """
  use GenServer

  alias Agt.Agent
  alias Agt.Commands
  alias Agt.Config
  alias Agt.Message.ModelMessage
  alias Agt.REPL.Editor

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
        handle_input(prompt)
        send(self(), :prompt)
    end

    {:noreply, state}
  end

  defp handle_input("/role " <> role_name) do
    role_name = String.trim(role_name)

    case Agt.Commands.load_role(role_name) do
      {:ok, _} ->
        IO.puts("Successfully loaded role: #{role_name}")

      {:error, {:not_found, role_name}} ->
        IO.puts("Error: Role not found: #{role_name}")
    end
  end

  defp handle_input(input) do
    case Commands.send_messages(input) do
      {:ok, response} ->
        handle_text_parts(response)

      {:error, :timeout} ->
        IO.puts("Request timed out.")

      {:error, reason} ->
        IO.puts("An error occurred: #{inspect(reason)}")
    end
  end

  defp handle_text_parts(parts) do
    for %{body: body} = part <- parts, match?(%ModelMessage{}, part), String.trim(body) != "" do
      IO.puts("")
      IO.puts(body)
    end
  end

  defp display_startup_message(%{rules: nil}), do: IO.puts("Rules not loaded")
  defp display_startup_message(%{rules: rules}), do: IO.puts("Rules loaded from #{rules}")
end
