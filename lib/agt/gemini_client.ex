defmodule Agt.GeminiClient do
  @moduledoc """
  Client for interacting with Google Gemini API
  """

  alias Agt.Config
  alias Agt.Message.{UserMessage, ModelMessage, FunctionCall, FunctionResponse}
  alias Agt.Tools

  require Logger

  def generate_content(conversation, %{body: system_prompt}) do
    debug(conversation)

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

    case Req.post(url(), json: body, headers: headers, receive_timeout: 180_000) do
      {:ok, %{status: 200, body: response_body}} ->
        parsed_response = parse_response(response_body)
        total_token_count = get_in(response_body, ["usageMetadata", "totalTokenCount"])
        {:ok, parsed_response, %{total_tokens: total_token_count}}

      {:ok, %{status: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp make_turn(%UserMessage{body: body}), do: %{role: "user", parts: %{text: body}}
  defp make_turn(%ModelMessage{body: body}), do: %{role: "model", parts: %{text: body}}

  defp make_turn(%FunctionCall{name: name, arguments: _args}),
    do: %{role: "function_call", parts: %{functionCall: %{name: name, args: %{}}}}

  defp make_turn(%FunctionResponse{name: name, result: result}),
    do: %{
      role: "function_result",
      parts: %{functionResponse: %{name: name, response: %{result: result}}}
    }

  defp parse_response(%{"candidates" => [%{"finishReason" => "MALFORMED_FUNCTION_CALL"} | _]}) do
    [%ModelMessage{body: "Malformed function call. Please try again."}]
  end

  defp parse_response(%{"candidates" => [%{"content" => %{"parts" => parts}} | _]}) do
    for part <- parts, do: part |> parse_part() |> tap(&debug/1)
  end

  defp parse_part(%{"text" => text}), do: %ModelMessage{body: text}

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

  defp url do
    {:ok, api_key} = Config.get_api_key()
    {:ok, model_name} = Config.get_model()

    "https://generativelanguage.googleapis.com/v1beta/models/#{model_name}:" <>
      "generateContent?key=#{api_key}"
  end

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
