defmodule Agt.GeminiClient do
  @moduledoc """
  Client for interacting with Google Gemini API
  """

  @base_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-preview-06-05:generateContent"

  def generate_content(message, api_key) do
    headers = [
      {"Content-Type", "application/json"}
    ]

    body = %{
      contents: [
        %{
          parts: [
            %{text: message}
          ]
        }
      ]
    }

    url = "#{@base_url}?key=#{api_key}"

    case Req.post(url, json: body, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: response_body}} ->
        parse_response(response_body)

      {:ok, %{status: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp parse_response(response) do
    case response do
      %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text} | _]}} | _]} ->
        {:ok, text}

      %{"error" => error} ->
        {:error, "API error: #{inspect(error)}"}

      _ ->
        {:error, "Unexpected response format: #{inspect(response)}"}
    end
  end
end
