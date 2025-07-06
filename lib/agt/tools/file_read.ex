defmodule Agt.Tools.FileRead do
  alias Agt.Tools.FileList

  require Logger

  def name, do: "file_read"

  def meta do
    %{
      name: name(),
      description: """
        Reads the content of a file belonging to the project.

        Expects a `path` argument, to always be provided.

        Example:
        `file_read(path="path/to/my_file.txt")`

        **Warning:** A call to this function without the `path` argument will result in failure!
        NEVER do something like `file_read()` (with no arguments)!

        On success, returns an object with the following properties:

        - `path`: the path of the file that was read.
        - `status`: the status of the read operation, set to `success`.
        - `content`: the content of the file that was read.

        On failure, returns an object with the following properties:

        - `path`: the path of the file that was meant to be read, if it is provided as an argument.
        - `status`: the status of the read operation, set to `failure`.
        - `error`: a string describing the error.
      """,
      parameters: %{
        type: "object",
        properties: %{
          path: %{
            type: "string",
            description: """
              The path of the file to read.

              Must match a path returned by the `file_list` tool.
            """
          }
        },
        required: ["path"]
      }
    }
  end

  def call(%{path: path} = arguments) do
    module_name = __MODULE__ |> to_string() |> String.split(".") |> List.last()
    "#{module_name}: #{arguments |> inspect(printable_limit: 48)}" |> Logger.debug()

    file_list = FileList.get_list()

    if Enum.member?(file_list, path) do
      case File.read(path) do
        {:ok, content} ->
          %{path: path, status: "success", content: content}

        {:error, reason} ->
          %{path: path, status: "failure", error: "Failed to read file: #{reason}"}
      end
    else
      %{path: path, status: "failure", error: "File not found"}
    end
  end

  def call(%{}) do
    %{status: "failure", error: "Please provide required argument `path`"}
  end

  def call(_args) do
    %{status: "failure", error: "Unexpected arguments. Expected `path`"}
  end
end
