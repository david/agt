defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.Config
  alias Agt.Message.{FunctionCall, FunctionResponse, Prompt, Response}
  alias Agt.Session
  alias Agt.Tools

  @prompt " "

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
    show_prompt()

    get_prompt()
    |> Session.prompt()
    |> handle_response()

    loop()
  end

  defp handle_response(nil), do: nil

  defp handle_response({:ok, response}) when is_list(response) do
    handle_text_parts(response)
    handle_function_calls(response)
  end

  defp handle_response({:error, :timeout}) do
    # The session genserver will handle retries
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

  defp show_prompt do
    IO.write(@prompt)
  end

  defp get_prompt do
    [%Prompt{body: get_multiline_input([])}]
  end

  defp get_multiline_input(lines) do
    # Show continuation prompt after first line
    prompt = if length(lines) == 0, do: "", else: "… "

    line =
      :io.get_line(:standard_io, prompt)
      |> to_string()
      |> String.trim_trailing("\n")

    cond do
      # Check if last two lines are empty (triple enter to send)
      length(lines) >= 1 and line == "" and List.last(lines) == "" ->
        lines
        # Remove the last empty line
        |> Enum.drop(-1)
        |> Enum.join("\n")
        |> String.trim()

      # Continue collecting lines
      true ->
        get_multiline_input(lines ++ [line])
    end
  end

  defp display_startup_message(status) do
    case status do
      :resumed -> IO.puts("Resuming previous conversation...")
      {:warning, message} -> IO.puts("Warning: #{message}")
      _ -> :ok
    end
  end
end
