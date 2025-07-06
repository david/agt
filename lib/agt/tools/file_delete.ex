defmodule Agt.Tools.FileDelete do
  require Logger

  def name, do: "file_delete"

  def meta do
    %{
      name: name(),
      description: """
        Deletes a file from the project.

        Expects a `path` argument to always be provided.

        Example:
        `file_delete(path="path/to/my_file.txt")`

        **Warning:** A call to this function without the `path` argument will fail.

        On success, returns an object with the following properties:

        - `path`: the path of the file that was deleted.
        - `status`: the status of the delete operation, set to `success`.

        On failure, returns an object with the following properties:

        - `path`: the path of the file that was meant to be deleted, if it is provided as an argument.
        - `status`: the status of the delete operation, set to `failure`.
        - `error`: a string describing the error.
      """,
      parameters: %{
        type: "object",
        properties: %{
          path: %{
            type: "string",
            description: """
            The path of the file to write.

            - Must be a path relative to the project root.
            - Must not resolve to a path outside the project root.
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

    expanded_path = Path.expand(path)

    if String.starts_with?(expanded_path, File.cwd!()) do
      case File.rm(expanded_path) do
        {:error, reason} ->
          %{path: path, status: "failure", error: "Failed to write file: #{reason}"}

        :ok ->
          %{path: path, status: "success"}
      end
    end
  end

  def call(%{}) do
    %{error: "Please provide required arguments `path` and `content`"}
  end

  def call(_args) do
    %{error: "Unexpected arguments. Expected `path` and `content`"}
  end
end
