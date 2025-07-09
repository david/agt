defmodule Agt.Tools.Shell do
  @moduledoc """
  A tool for executing shell commands.
  """

  def name, do: "shell_command"

  def visible_properties, do: [:command]

  def meta do
    %{
      name: name(),
      description: """
      Execute a shell command.

      Returns both stdout and stderr .

      Expectations for required parameters:
      - `shell_command` MUST be provided just as if you were writing it in the shell. This means
      that certain characters need to be adequately escaped, if you don't want them to be interpreted
      by the shell. These would be characters like ```, `$`, and others.

      Double check that you are actually providing the `shell_command` parameter. Failing to
      follow the above will result in tool failure.

      Do your best to get the function call right. In the event that you fail to do so, do not fret,
      take a deep breath, and try again. You can do this!
      """,
      parameters: %{
        type: "object",
        properties: %{
          command: %{
            type: "string",
            description: "The shell command to execute via `sh -c`."
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
      error:
        "What is the command you wanted to execute? Please provide it as the `shell_command` argument."
    }
  end
end
