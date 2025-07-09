defmodule Agt.Tools.FileWrite do
  @moduledoc """
  A tool for writing files to the filesystem.
  """

  require Logger

  def name, do: "file_write"

  def visible_properties, do: [:path]

  def meta do
    %{
      name: name(),
      description: """
      Write the text contents to a given file path.

      Requirements for successfully calling this function:
      - The `file_path` property MUST be provided and MUST be a relative path.
      - The `text_contents` property MUST also be provided.
      - The `text_contents` property MUST be the exact literal text to write to the file.

      **Warning:** Failing to strictly follow any of the above requirements will result in tool
      failure!

      You must always use this tool whenever you want to write to a file.
      """,
      parameters: %{
        type: "object",
        properties: %{
          file_path: %{
            type: "string",
            description: """
            The path of the file, relative to the current directory, to write the contents to
            (e.g., lib/agt/my_module.ex).

            Parent directories will be created if they don't exist.
            """
          },
          text_contents: %{
            type: "string",
            description: """
            The exact literal text that will be written to the file (e.g. "defmodule MyModule do\nend").
            """
          }
        },
        required: ["file_path", "text_contents"]
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
          %{error: "Failed to write file: #{reason}"}

        :ok ->
          %{
            output: """
            The `file_write` tool wrote to #{path} successfully. Good job! You don't need to repeat
            this operation unless you want to make more changes to the file.
            """
          }
      end
    end
  end

  def call(%{}) do
    %{error: "Please provide the content to write and the path of the file to write to."}
  end

  def call(_args) do
    %{error: "Unexpected arguments. Expected `path` and `content`"}
  end
end
