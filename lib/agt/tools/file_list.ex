defmodule Agt.Tools.FileList do
  @moduledoc """
  A tool for listing files in the project.
  """

  require Logger

  def name, do: "file_list"

  def visible_properties, do: []

  def meta do
    %{
      name: name(),
      description: "Recursively list files and directories inside the current directory."
    }
  end

  def call(_args) do
    # TODO: This is a bit of a hack, but it works for now. The list of files
    # is hardcoded, but it would be better to dynamically generate it based
    # on the project structure.

    __MODULE__ |> to_string() |> String.split(".") |> List.last() |> Logger.debug()

    %{output: get_list()}
  end

  def get_list do
    {output, 0} = System.cmd("fdfind", [])

    output
    |> String.split("\n")
  end
end
