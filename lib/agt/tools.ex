defmodule Agt.Tools do
  @moduledoc """
  Tools for interacting with the AI
  """

  alias Agt.Tools.FileList
  alias Agt.Tools.FileRead
  alias Agt.Tools.FileWrite

  # TODO: I imagine the `meta` functions could be implemented with some elixir magic,
  # as attributes of the `call` function. But is it worth it?

  require Logger

  def list do
    [
      FileList,
      FileRead,
      FileWrite
    ]
  end

  def call(tool, args), do: list() |> Enum.find(&(&1.name() == tool)) |> then(& &1.call(args))
end
