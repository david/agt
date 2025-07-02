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

  @doc """
  Retrieves the Gemini model name from the application environment.
  Defaults to "gemini-2.5-flash" if not configured.
  """
  def get_model do
    {:ok, Application.get_env(:agt, :model, "gemini-2.5-pro")}
  end
end
