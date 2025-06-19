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

        Returns the content of the file as a string.

        On failure, returns an object with the format `{"error": "<message>"}`.
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
    "#{module_name}: #{arguments |> inspect(printable_limit: 48)}" |> Logger.info()

    file_list = FileList.call(%{})

    if Enum.member?(file_list, path) do
      case File.read(path) do
        {:error, reason} ->
          %{error: "Failed to read file: #{reason}"}

        {:ok, content} ->
          content
      end
    else
      %{error: "File not found: #{path}"}
    end
  end

  def call(%{}) do
    %{error: "Error: missing required argument `path`"}
  end

  def call(_args) do
    %{error: "Error: unexpected arguments. Expected `path`"}
  end
end
