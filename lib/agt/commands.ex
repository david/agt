defmodule Agt.Commands do
  @moduledoc """
  This module is responsible for handling user-facing commands.
  """

  alias Agt.Agent
  alias Agt.Message.UserMessage

  @doc """
  Sends a prompt to the session asynchronously.

  ## Parameters

    - `input`: The raw user input string.
    - `repl_pid`: The PID of the REPL process to send updates to.
  """
  @spec send_messages(String.t(), pid()) :: :ok
  def send_messages(input, repl_pid) do
    [%UserMessage{body: input}]
    |> Agent.send_messages(repl_pid)
  end

  def load_role(_name) do
    # {:ok, prompt} = load_prompt("prompts/#{name}.md")
    #
    # Session.reset(prompt)
    {:ok, nil}
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
