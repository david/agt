defmodule Agt.Tools.FileRead do
  @moduledoc """
  A tool for reading files from the filesystem.
  """

  alias Agt.Tools.FileList

  require Logger

  def name, do: "file_read"

  def visible_properties, do: [:path]

  def meta do
    %{
      name: name(),
      description: "Read the content of a file given its path.",
      parameters: %{
        type: "object",
        properties: %{
          path: %{
            type: "string",
            description: """
            The path of the file to read (e.g., lib/agt/my_module.ex).
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
          %{output: content}

        {:error, reason} ->
          %{error: "Could not read file: #{reason}"}
      end
    else
      %{error: "File not found"}
    end
  end

  def call(%{}) do
    %{error: "Please provide the path of the file to read."}
  end

  def call(_args) do
    %{error: "Unexpected arguments. Expected `path`"}
  end
end
