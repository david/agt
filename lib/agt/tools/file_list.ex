defmodule Agt.Tools.FileList do
  require Logger

  def name, do: "file_list"

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

    __MODULE__ |> to_string() |> String.split(".") |> List.last() |> Logger.info()

    [
      "mix.exs",
      "mix.lock"
      | Path.wildcard("{lib,test}/**/*.{ex,exs}")
    ]
  end
end
