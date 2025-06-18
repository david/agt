defmodule Agt.Tools do
  @moduledoc """
  Tools for interacting with the AI
  """

  # TODO: I imagine the `meta` functions could be implemented with some elixir magic,
  # as attributes of the `call` function. But is it worth it?

  defmodule ListFiles do
    def name, do: "list_files"

    def meta do
      %{
        name: name(),
        description: """
          Lists all relevant project files.

          Returns a list of paths relative to the project root.
        """,
        parameters: %{
          type: "object",
          properties: %{}
        }
      }
    end

    def call(_args) do
      # TODO: This is a bit of a hack, but it works for now. The list of files
      # is hardcoded, but it would be better to dynamically generate it based
      # on the project structure.

      [
        "mix.exs",
        "mix.lock"
        | Path.wildcard("{lib,test}/**/*.{ex,exs}")
      ]
    end
  end

  defmodule ReadFile do
    def name, do: "read_file"

    def meta do
      %{
        name: name(),
        description: "Reads the content of a file belonging to the project.",
        parameters: %{
          type: "object",
          properties: %{
            path: %{
              type: "string",
              description: """
                The path of the file to read. 

                Must match a path returned by the `list_files` tool.
              """
            }
          },
          required: ["path"]
        }
      }
    end

    def call(%{path: path}) do
      file_list = ListFiles.call(%{})

      if Enum.member?(file_list, path) do
        case File.read(path) do
          {:error, reason} ->
            {:error, "Failed to read file: #{reason}"}

          {:ok, content} ->
            content
        end
      else
        {:error, "File not found: #{path}"}
      end
    end
  end

  defmodule WriteFile do
    def name, do: "write_file"

    def meta do
      %{
        name: name(),
        description: "Writes a file to the project.",
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
      expanded_path = Path.expand(path)

      if String.starts_with?(expanded_path, File.cwd!()) do
        case File.write(expanded_path, content) do
          {:error, reason} ->
            {:error, "Failed to write file: #{reason}"}

          result ->
            result
        end
      end
    end
  end

  def list do
    [
      ListFiles,
      ReadFile,
      WriteFile
    ]
  end

  def call(tool, args), do: list() |> Enum.find(&(&1.name() == tool)) |> then(& &1.call(args))
end
