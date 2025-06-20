defmodule Agt.Tools.FileDelete do
  require Logger

  def name, do: "file_delete"

  def meta do
    %{
      name: name(),
      description: """
        Deletes a file from the project.

        Expects a `path` argument to always be provided.

        Returns the string `:ok` on success.

        On failure, returns an object with the format `{"error": "<message>"}`.
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
    "#{module_name}: #{arguments |> inspect(printable_limit: 48)}" |> Logger.info()

    expanded_path = Path.expand(path)

    if String.starts_with?(expanded_path, File.cwd!()) do
      case File.rm(expanded_path) do
        {:error, reason} ->
          %{error: "Failed to write file: #{reason}"}

        result ->
          result
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
