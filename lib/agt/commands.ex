defmodule Agt.Commands do
  @moduledoc """
  This module is responsible for handling user-facing commands.
  """

  alias Agt.Message.Prompt
  alias Agt.Session

  @doc """
  Sends a prompt to the session.

  ## Parameters

    - `input`: The raw user input string.

  ## Returns

    - `{:ok, response}`: The response from the session.
    - `{:error, :timeout}`: If the session times out.
  """
  @spec send_prompt(String.t()) :: {:ok, list()} | {:error, :timeout}
  def send_prompt(input) do
    [%Prompt{body: input}]
    |> Session.prompt()
  end
end
