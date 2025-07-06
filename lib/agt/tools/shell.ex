defmodule Agt.Tools.Shell do
  @moduledoc """
  A tool for executing shell commands.
  """

  def name, do: "shell"

  def meta do
    %{
      name: name(),
      description: "Execute a shell command.",
      parameters: %{
        type: "object",
        properties: %{
          command: %{
            type: "string",
            description: """
            The shell command to execute via `sh -c`.

            Both stdout and stderr are captured.
            Be mindful of security implications when executing commands.
            """
          }
        },
        required: ["command"]
      }
    }
  end

  def call(%{command: command}) when is_binary(command) do
    {output, _status} = System.cmd("sh", ["-c", command], stderr_to_stdout: true)

    %{output: output}
  end

  def call(_args) do
    %{
      error: "Please provide the command to execute."
    }
  end
end
