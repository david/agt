defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.Agent
  alias Agt.AgentSupervisor
  alias Agt.Config
  alias Agt.Message.{FunctionCall, Response}
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
    :io.get_line(:standard_io, "")
    |> to_string()
    |> String.trim()
  end

  defp handle_input("", agent), do: loop(agent)

  defp handle_input(message, agent) do
    IO.puts("")
    IO.puts("[Prompt]")
    IO.puts("")

    handle_response(Agent.prompt(agent, message), agent)
  end

  defp handle_response({:error, :timeout}, agent) do
    IO.puts("[Timeout: retrying...]")
    IO.puts("")

    agent
    |> Agent.retry()
    |> handle_response(agent)

    loop(agent)
  end

  defp handle_response({:ok, %Response{body: message}}, agent) do
    IO.puts(message)
    IO.puts("")

    loop(agent)
  end

  defp handle_response({:ok, %FunctionCall{name: name, arguments: args}}, agent) do
    IO.puts("[FunctionCall name=#{name} args=#{inspect(args)}]")
    IO.puts("")

    Tools.call(name, args)
    |> Agent.function_result(name, agent)
    |> handle_response(agent)
  end
end
