defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.Agent
  alias Agt.AgentSupervisor
  alias Agt.Config

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
    :io.get_line(:standard_io, "")
    |> to_string()
    |> String.trim()
  end

  defp handle_input("", agent), do: loop(agent)

  defp handle_input(message, agent) do
    IO.puts("")
    IO.puts("AI: ...")
    IO.puts("")

    {:ok, response} = Agent.prompt(agent, message)
    IO.puts("AI: #{response}")
    IO.puts("")

    loop(agent)
  end
end
