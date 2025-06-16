defmodule Agt.Config do
  @moduledoc """
  Configuration management for AGT
  """

  def get_api_key do
    case System.get_env("GEMINI_API_KEY") do
      nil ->
        {:error, "GEMINI_API_KEY environment variable not set"}

      "" ->
        {:error, "GEMINI_API_KEY environment variable is empty"}

      key ->
        {:ok, key}
    end
  end
end
