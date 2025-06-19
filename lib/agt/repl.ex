defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.Agent
  alias Agt.AgentSupervisor
  alias Agt.Config
  alias Agt.Message.{FunctionCall, FunctionResponse, Prompt, Response}
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

    get_prompt() 
    |> send_prompt(agent)
    |> handle_response(agent)
    
    loop(agent)
  end

  defp send_prompt(%Prompt{body: ""}, _agent), do: nil
  defp send_prompt(%Prompt{} = prompt, agent), do: Agent.prompt(prompt, agent)

  defp handle_response(nil, _agent), do: nil

  defp handle_response({:ok, response}, agent) when is_list(response) do
    Enum.each(response, &handle_response_part(&1, agent))
  end

  defp handle_response({:error, :timeout}, agent) do
    agent
    |> Agent.retry()
    |> handle_response(agent)
  end

  defp handle_response_part(%Response{body: message}, _agent) do
    IO.puts("")
    IO.puts(message)
  end

  defp handle_response_part(%FunctionCall{name: name, arguments: args}, agent) do
    IO.puts("")
    IO.puts("[Function Call: name=#{name} arguments=#{inspect(args)}]")

    %FunctionResponse{name: name, result: Tools.call(name, args)}
    |> Agent.function_result(agent)
    |> handle_response(agent)
  end

  defp show_prompt do
    IO.write(@prompt)
  end

  defp get_prompt do
    %Prompt{body: get_multiline_input([])}
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
end
