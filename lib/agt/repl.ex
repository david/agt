defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.{Config, Conversation}

  @prompt " "

  def start do
    case Config.get_api_key() do
      {:ok, _api_key} ->
        loop()

      {:error, error} ->
        IO.puts("Error: #{error}")
        IO.puts("Please set the GEMINI_API_KEY environment variable")
        System.halt(1)
    end
  end

  defp loop do
    show_prompt()

    get_input() |> handle_input()
  end

  defp show_prompt do
    IO.write(@prompt)
  end

  defp get_input do
    :io.get_line(:standard_io, "")
    |> to_string()
    |> String.trim()
  end

  defp handle_input(""), do: loop()

  defp handle_input(message) do
    IO.puts("")
    IO.puts("AI: ...")
    IO.puts("")

    {:ok, response} = Conversation.prompt(message)
    IO.puts("AI: #{response}")
    IO.puts("")

    loop()
  end
end
