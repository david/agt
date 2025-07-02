defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.Commands
  alias Agt.Config
  alias Agt.Message.{FunctionCall, FunctionResponse, ModelMessage}
  alias Agt.REPL.InputParser
  alias Agt.REPL.Prompt
  alias Agt.Session
  alias Agt.Tools

  def child_spec(opts) do
    %{
      id: Agt.REPL,
      start: {Agt.REPL, :start, opts}
    }
  end

  def start(_) do
    case Config.get_api_key() do
      {:ok, _api_key} ->
        display_startup_message(Session.get_startup_status())
        loop()

      {:error, error} ->
        IO.puts("Error: #{error}")
        IO.puts("Please set the GEMINI_API_KEY environment variable")
        System.halt(1)
    end
  end

  defp loop do
    IO.puts("")
    begin_prompt()

    # Read the first line of input
    first_line = IO.gets("")

    case InputParser.parse_first_line(first_line) do
      {:single_line, prompt} ->
        end_prompt()
        handle_input(prompt)
        loop()

      {:multi_line_start, initial_line_content} ->
        # Start collecting multi-line input
        case collect_multi_line([initial_line_content]) do
          :ignore ->
            loop()

          prompt ->
            end_prompt()
            handle_input(prompt)
            loop()
        end

      :ignore ->
        loop()
    end
  end

  defp collect_multi_line(current_lines) do
    # No prompt for continuation lines
    line = IO.gets("")

    case InputParser.parse_continuation_line(line, current_lines) do
      {:continue, updated_lines} ->
        collect_multi_line(updated_lines)

      {:finished, final_prompt} ->
        final_prompt
    end
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
    Commands.send_messages(input)
    |> handle_response()
  end

  defp handle_response(nil), do: nil

  defp handle_response({:ok, response}) when is_list(response) do
    handle_text_parts(response)
    handle_function_calls(response)
  end

  defp handle_response({:error, :timeout}) do
    :ok
  end

  defp handle_text_parts(parts) do
    for %{body: body} = part <- parts, match?(%ModelMessage{}, part), String.trim(body) != "" do
      IO.puts("")
      IO.puts(body)
    end
  end

  defp handle_function_calls(parts) do
    results =
      for(
        %{name: name, arguments: args} = part <- parts,
        match?(%FunctionCall{}, part),
        do: %FunctionResponse{name: name, result: Tools.call(name, args)}
      )

    if Enum.any?(results) do
      results
      |> Session.send_messages()
      |> handle_response()
    end
  end

  defp display_startup_message(%{session: session, rules: rules}) do
    if rules do
      IO.puts("Rules loaded from #{rules}")
    else
      IO.puts("Rules not loaded")
    end

    case session do
      :resumed ->
        IO.puts("Resuming previous conversation...")

      :new ->
        IO.puts("Starting new conversation...")
    end
  end

  defp begin_prompt() do
    {:ok, columns} = :io.columns()

    %{total_tokens: total_tokens, max_tokens: max_tokens} = Session.get_meta()

    case Prompt.format(total_tokens, max_tokens, columns) do
      {:ok, prompt_string} ->
        IO.write(prompt_string)

      {:error, :column_width_too_small} ->
        # Fallback for very small terminals where ruler cannot be displayed
        IO.write(Prompt.format_fallback())
    end
  end

  defp end_prompt() do
    IO.write(Prompt.format_end_prompt())
  end
end
