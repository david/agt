defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.Agent
  alias Agt.AgentSupervisor
  alias Agt.Config
  alias Agt.LLM
  alias Agt.Tools

  @prompt " "

  def start do
    case Config.get_api_key() do
      {:ok, _api_key} ->
        {:ok, agent} = AgentSupervisor.start_agent()

        loop(agent)

      {:error, error} ->
        IO.puts("Error: #{error}")
        IO.puts("Please set the GEMINI_API_KEY environment variable")
        System.halt(1)
    end
  end

  defp loop(agent) do
    show_prompt()

    get_input() |> handle_input(agent)
  end

  defp show_prompt do
    IO.write(@prompt)
  end

  defp get_input do
    get_multiline_input([])
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

  defp handle_input("", agent), do: loop(agent)

  defp handle_input(message, agent) do
    IO.puts("")
    IO.puts("AI: ...")
    IO.puts("")

    handle_response(Agent.prompt(agent, message), agent)
  end

  defp handle_response({:ok, %LLM.Message{body: message}}, agent) do
    IO.puts("AI: #{message}")
    IO.puts("")

    loop(agent)
  end

  defp handle_response({:ok, %LLM.FunctionCall{name: name, arguments: args}}, agent) do
    Tools.call(name, args)
    |> Agent.function_result(name, agent)
    |> handle_response(agent)
  end
end
