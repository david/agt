defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.Commands
  alias Agt.Config
  alias Agt.Message.{FunctionCall, FunctionResponse, Response}
  alias Agt.Session
  alias Agt.Tools

  @prompt " "
  @continuation_prompt " "

  def start do
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
    display_prompt(@prompt)

    input_lines = read_multiline_input([], Time.utc_now())
    input = Enum.join(input_lines, "\n")

    if String.trim(input) != "" do
      lines_to_clear = length(input_lines) + 2

      reprint_text =
        case input_lines do
          [first_line | rest_lines] ->
            ([@prompt <> first_line] ++ Enum.map(rest_lines, &(@continuation_prompt <> &1)))
            |> Enum.join("\n")

          [] ->
            ""
        end

      reprint_historical_prompt(reprint_text, lines_to_clear)

      handle_input(input)
    end

    loop()
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
    Commands.send_prompt(input)
    |> handle_response()
  end

  defp read_multiline_input(lines, timestamp) do
    now = Time.utc_now()

    if Time.diff(now, timestamp, :millisecond) > 25 do
      display_prompt(@continuation_prompt)
    end

    line = IO.gets("") |> String.trim_trailing("\n")

    cond do
      line == "" and Enum.at(lines, -1) == "" ->
        lines |> Enum.take(length(lines) - 1)

      true ->
        read_multiline_input(lines ++ [line], now)
    end
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
    for %{body: body} = part <- parts, match?(%Response{}, part), String.trim(body) != "" do
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
      |> Session.prompt()
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

    IO.puts("---")
  end

  defp display_prompt(prompt) do
    IO.write(IO.ANSI.light_white() <> prompt <> IO.ANSI.reset())
  end

  defp reprint_historical_prompt(submitted_text, lines_to_clear) do
    IO.write(
      # Clear screen from cursor to end
      IO.ANSI.cursor_up(lines_to_clear) <>
        "\e[J" <>
        IO.ANSI.light_black() <>
        submitted_text <>
        IO.ANSI.reset() <>
        "\n"
    )
  end
end
