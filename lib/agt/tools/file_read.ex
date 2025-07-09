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
      description: """
      Read the content of a file given its path.

      Never read a file without first checking that it exists in the listing provided by
      the `#{Agt.Tools.FileList.name()}` tool.

      It is crucial that you follow the requirements below:
      - ALWAYS include `file_path` as part of the function call.
      - ALWAYS check that `file_path` exists.

      If you need to read multiple files in one turn and you are not performing any destructive
      operation in that same turn, you can get the list of files only once. There is no point in
      listing files more than once in that case. It is a waste of time and tokens.
      """,
      parameters: %{
        type: "object",
        properties: %{
          file_path: %{
            type: "string",
            description: """
            The path of the file to read (e.g., lib/agt/my_module.ex).
            """
          }
        },
        required: ["file_path"]
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
