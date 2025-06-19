defmodule Agt.GeminiClient do
  @moduledoc """
  Client for interacting with Google Gemini API
  """

  alias Agt.Config
  alias Agt.Message.{Prompt, Response, FunctionCall, FunctionResponse}
  alias Agt.Tools

  @base_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent"

  def generate_content(conversation) do
    {:ok, api_key} = Config.get_api_key()

    headers = [
      {"Content-Type", "application/json"}
    ]

    body = %{
      contents: Enum.map(conversation, &make_turn/1),
      tools: %{
        functionDeclarations: Tools.list() |> Enum.map(& &1.meta())
      }
    }

    url = "#{@base_url}?key=#{api_key}"

    case Req.post(url, json: body, headers: headers, receive_timeout: 60_000) do
      {:ok, %{status: 200, body: response_body}} ->
        {:ok, parse_response(response_body)}

      {:ok, %{status: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp make_turn(%Prompt{body: body}), do: %{role: "user", parts: %{text: body}}
  defp make_turn(%Response{body: body}), do: %{role: "model", parts: %{text: body}}

  defp make_turn(%FunctionCall{name: name, arguments: _args}),
    do: %{role: "function_call", parts: %{functionCall: %{name: name, args: %{}}}}

  defp make_turn(%FunctionResponse{name: name, result: result}),
    do: %{
      role: "function_result",
      parts: %{functionResponse: %{name: name, response: %{result: result}}}
    }

  defp parse_response(%{"candidates" => [%{"content" => %{"parts" => parts}} | _]}) do
    for part <- parts, do: parse_part(part)
  end

  # defp parse_response(%{"error" => error}), do: {:error, "API error: #{inspect(error)}"}
  # defp parse_response(_), do: {:error, "Unexpected response format"}

  defp parse_part(%{"text" => text}), do: %Response{body: text}

  defp parse_part(%{"functionCall" => %{"name" => name, "args" => args}}),
    do: %FunctionCall{
      name: name,
      arguments:
        args
        |> Enum.map(fn {name, value} ->
          {String.to_existing_atom(name), value}
        end)
        |> Enum.into(%{})
    }
end
