defmodule Agt.ModelSpecification do
  @moduledoc """
  This module maintains a static map of known Gemini model names to their specifications.
  """

  @models_spec %{
    "gemini-2.5-pro" => %{max_tokens: 1_048_576},
    "gemini-2.5-flash" => %{max_tokens: 1_048_576}
    # Add other Gemini models and their specifications as needed
  }

  @doc """
  Returns the specification for a given Gemini `model_name`.

  If the `model_name` is found, its specification map is returned.
  Otherwise, a default "unknown" specification map is returned.

  ## Examples

      iex> Agt.ModelSpecification.get_spec("gemini-pro")
      %{max_tokens: 30720}

      iex> Agt.ModelSpecification.get_spec("unknown-model")
      %{max_tokens: 0}
  """
  def get_spec(model_name) when is_binary(model_name) do
    Map.get(@models_spec, model_name, %{max_tokens: 0})
  end
end
