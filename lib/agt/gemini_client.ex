defmodule Agt.GeminiClient do
  @moduledoc """
  Client for interacting with Google Gemini API
  """

  alias Agt.Config
  alias Agt.Message.{Prompt, Response, FunctionCall, FunctionResponse}
  alias Agt.Tools

  require Logger

  # TODO: Make this configurable
  @base_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

  def generate_content(conversation, %{body: system_prompt}) do
    debug(conversation)

    {:ok, api_key} = Config.get_api_key()

    headers = [
      {"Content-Type", "application/json"}
    ]

    body =
      %{
        contents: Enum.map(conversation, &make_turn/1),
        tools: %{
          functionDeclarations: Tools.list() |> Enum.map(& &1.meta())
        },
        systemInstruction: %{parts: [%{text: system_prompt}]}
      }

    url = "#{@base_url}?key=#{api_key}"

    case Req.post(url, json: body, headers: headers, receive_timeout: 180_000) do
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

  defp parse_response(%{"candidates" => [%{"finishReason" => "MALFORMED_FUNCTION_CALL"} | _]}) do
    [%Response{body: "Malformed function call. Please try again."}]
  end

  defp parse_response(%{"candidates" => [%{"content" => %{"parts" => parts}} | _]}) do
    for part <- parts, do: part |> parse_part() |> tap(&debug/1)
  end

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

  defp debug(conversation) when is_list(conversation) do
    conversation
    |> Enum.reverse()
    |> List.first()
    |> debug()
  end

  defp debug(part) do
    part
    |> inspect(printable_limit: 48)
    |> Logger.debug()
  end
end
