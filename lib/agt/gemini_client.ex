defmodule Agt.GeminiClient do
  @moduledoc """
  Client for interacting with Google Gemini API
  """

  alias Agt.Config
  alias Agt.LLM
  alias Agt.Operator

  @base_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-preview-06-05:generateContent"

  def generate_content(conversation) do
    {:ok, api_key} = Config.get_api_key()

    headers = [
      {"Content-Type", "application/json"}
    ]

    body = %{
      contents: Enum.map(conversation, &make_turn/1)
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

  defp make_turn(%Operator.Message{body: body}), do: %{role: "user", parts: %{text: body}}
  defp make_turn(%LLM.Message{body: body}), do: %{role: "model", parts: %{text: body}}

  defp parse_response(response) do
    case response do
      %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text} | _]}} | _]} ->
        {:ok, %LLM.Message{body: text}}

      %{"error" => error} ->
        {:error, "API error: #{inspect(error)}"}

      _ ->
        {:error, "Unexpected response format: #{inspect(response)}"}
    end
  end
end
