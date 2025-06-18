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
        parse_response(response_body)

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

  defp parse_response(response) do
    case response do
      %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text} | _]}} | _]} ->
        {:ok, %Response{body: text}}

      %{
        "candidates" => [
          %{
            "content" => %{
              "parts" => [%{"functionCall" => %{"name" => name, "args" => args}} | _]
            }
          }
          | _
        ]
      } ->
        {:ok,
         %FunctionCall{
           name: name,
           arguments:
             args
             |> Enum.map(fn {name, value} ->
               {String.to_existing_atom(name), value}
             end)
             |> Enum.into(%{})
         }}

      %{"error" => error} ->
        {:error, "API error: #{inspect(error)}"}

      _ ->
        {:error, "Unexpected response format: #{inspect(response)}"}
    end
  end
end
