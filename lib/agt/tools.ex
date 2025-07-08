defmodule Agt.Tools do
  @moduledoc """
  Tools for interacting with the AI
  """

  alias Agt.Tools.FileDelete
  alias Agt.Tools.FileList
  alias Agt.Tools.FileRead
  alias Agt.Tools.FileWrite
  alias Agt.Tools.Shell

  # TODO: I imagine the `meta` functions could be implemented with some elixir magic,
  # as attributes of the `call` function. But is it worth it?

  require Logger

  def list do
    [
      FileDelete,
      FileList,
      FileRead,
      FileWrite,
      Shell
    ]
  end

  def call(tool_name, args), do: get_tool(tool_name).call(args)

  def get_visible_properties(tool_name), do: get_tool(tool_name).visible_properties()

  defp get_tool(tool_name) do
    Enum.find(list(), &(&1.name() == tool_name))
  end
end
