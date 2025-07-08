defmodule Agt.Tools.FileWrite do
  require Logger

  def name, do: "file_write"

  def visible_properties, do: [:path]

  def meta do
    %{
      name: name(),
      description: "Write a file to a given path.",
      parameters: %{
        type: "object",
        properties: %{
          path: %{
            type: "string",
            description: """
            The path, relative to the current directory, to write the contents to
            (e.g., lib/agt/my_module.ex).

            Parent directories will be created if they don't exist.
            """
          },
          content: %{
            type: "string",
            description: """
            The file contents (e.g. "defmodule MyModule do\nend").
            """
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
          %{error: "Failed to write file: #{reason}"}

        :ok ->
          %{output: "File #{path} written successfully."}
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
