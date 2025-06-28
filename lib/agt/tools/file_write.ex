defmodule Agt.Tools.FileWrite do
  require Logger

  def name, do: "file_write"

  def meta do
    %{
      name: name(),
      description: """
        Writes a file to the project.

        Expects a `path` and `content` argument to always be provided.

        Example:
        `file_write(path="path/to/my_file.txt", content="This is the content of the file.")`

        **Warning:** A call to this function without either the `path` or the `content`
        arguments will fail.

        On success, returns an object with the following properties:

        - `path`: the path of the file that was written.
        - `status`: the status of the write operation, set to `success`.

        On failure, returns an object with the following properties:

        - `path`: the path of the file that was meant to be written, if it is provided as an argument.
        - `status`: the status of the write operation, set to `failure`.
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
          },
          content: %{
            type: "string",
            description: "The content to write to the file."
          }
        },
        required: ["path", "content"]
      }
    }
  end

  def call(%{path: path, content: content} = arguments) do
    module_name = __MODULE__ |> to_string() |> String.split(".") |> List.last()
    "#{module_name}: #{arguments |> inspect(printable_limit: 48)}" |> Logger.debug()

    expanded_path = Path.expand(path)

    if String.starts_with?(expanded_path, File.cwd!()) do
      File.mkdir_p!(Path.dirname(expanded_path))

      case File.write(expanded_path, content) do
        {:error, reason} ->
          %{path: path, status: "failure", error: "Failed to write file: #{reason}"}

        :ok ->
          %{path: path, status: "success"}
      end
    end
  end

  def call(%{}) do
    %{error: "Error: missing required arguments `path` and `content`"}
  end

  def call(_args) do
    %{error: "Error: unexpected arguments. Expected `path` and `content`"}
  end
end
