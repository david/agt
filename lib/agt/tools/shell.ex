defmodule Agt.Tools.Shell do
  @moduledoc """
  A tool for executing shell commands.
  """

  def name, do: "shell"

  def meta do
    %{
      name: name(),
      description: """
      Executes a system command and returns its combined standard output and standard error.

      This tool allows for the execution of arbitrary shell commands on the system where the agent
      is running. It captures and returns the combined output and the exit status of the command.

      Example:
      `shell(command: "ls -l /nonexistent_directory")`

      **Warning:** A call to this function without the `command` argument will fail.

      On success, returns an object with the following properties:
      - `command`: The command that was executed.
      - `output`: The combined standard output and standard error of the command as a single string.
      - `status`: The exit status code of the command as an integer.

      On failure (e.g., invalid arguments), returns an object with an `error` property.
      """,
      parameters: %{
        type: "object",
        properties: %{
          command: %{
            type: "string",
            description: """
            The shell command to execute.

            The command is executed via `sh -c`. Both stdout and stderr are captured.
            Be mindful of security implications when executing commands.
            """
          }
        },
        required: ["command"]
      }
    }
  end

  def call(%{command: command}) when is_binary(command) do
    {output, status} = System.cmd("sh", ["-c", command], stderr_to_stdout: true)
    %{command: command, output: output, status: status}
  end

  def call(_args) do
    %{
      error: "Please provide the required argument `command`."
    }
  end
end
