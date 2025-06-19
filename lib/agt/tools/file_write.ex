defmodule Agt.Tools.FileWrite do
  require Logger

  def name, do: "file_write"

  def meta do
    %{
      name: name(),
      description: """
        Writes a file to the project.

        Expects a `path` and `content` argument to always be provided.

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

  def call(%{path: path, content: content}) do
    Logger.info("FileWrite: path=#{path}")

    expanded_path = Path.expand(path)

    if String.starts_with?(expanded_path, File.cwd!()) do
      case File.write(expanded_path, content) do
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
