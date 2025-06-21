defmodule Agt.Tools.FileList do
  require Logger

  def name, do: "file_list"

  def meta do
    %{
      name: name(),
      description: """
        Lists all project files and directories.

        Directory contents are listed recursively.
        Directory names have a trailing slash appended.

        Example:

        - lib/agt/cli.ex is a file.
        - lib/agt/tools/ is a directory.

        On success, returns an object with the following properties:

        - `status`: the status of the list operation, set to `success`.
        - `files`: a list of all files and directories, relative to the project root.
      """,
      parameters: %{
        type: "object",
        properties: %{}
      }
    }
  end

  def call(_args) do
    # TODO: This is a bit of a hack, but it works for now. The list of files
    # is hardcoded, but it would be better to dynamically generate it based
    # on the project structure.

    __MODULE__ |> to_string() |> String.split(".") |> List.last() |> Logger.info()

    %{status: "success", files: get_list()}
  end

  def get_list do
    {output, 0} = System.cmd("fdfind", [])

    output
    |> String.split("\n")
  end
end
