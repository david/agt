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
    |> Session.send_prompt()
  end

  def load_role(name) do
    {:ok, prompt} = load_prompt("prompts/#{name}.md")

    Session.reset(prompt)
  end

  @doc """
  Loads a prompt from a file and sends it to a new session.

  ## Parameters

    - `path`: The path to the prompt file to load.

  ## Returns

    - `{:ok, name}`: On successful loading and sending of the prompt.
    - `{:error, {:not_found, name}}`: If the prompt file is not found.
  """
  @spec load_prompt(String.t()) :: {:ok, String.t()} | {:error, {:not_found, String.t()}}
  def load_prompt(path) do
    case File.read(path) do
      {:error, :enoent} ->
        {:error, {:not_found, path}}

      {:error, reason} ->
        {:error, reason}

      response ->
        response
    end
  end
end
