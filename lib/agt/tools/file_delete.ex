defmodule Agt.Tools.FileDelete do
  require Logger

  def name, do: "file_delete"

  def visible_properties, do: [:path]

  def meta do
    %{
      name: name(),
      description: "Delete a file given its path.",
      parameters: %{
        type: "object",
        properties: %{
          path: %{
            type: "string",
            description: "The path of the file to write, relative to the current directory."
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
          %{error: "Failed to write file: #{reason}"}

        :ok ->
          %{output: "File #{path} deleted successfully."}
      end
    end
  end

  def call(%{}) do
    %{error: "Please provide the path of the file to delete."}
  end

  def call(_args) do
    %{error: "Unexpected arguments. Expected `path`"}
  end
end
