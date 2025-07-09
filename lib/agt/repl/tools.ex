defmodule Agt.REPL.Tools do
  @moduledoc """
  Formats tool-related output for the REPL.
  """

  alias Agt.Message.FunctionCall
  alias Agt.Tools

  @doc """
  Formats a function call for display in the REPL.
  """
  def format_function_call(%FunctionCall{} = function_call) do
    "* " <> tool_name(function_call) <> "(" <> tool_arguments(function_call) <> ")"
  end

  defp tool_name(%FunctionCall{name: name}), do: IO.ANSI.magenta() <> name <> IO.ANSI.white()

  defp tool_arguments(%FunctionCall{name: name, arguments: args}) do
    args
    |> Enum.filter(fn {key, _value} -> key in Tools.get_visible_properties(name) end)
    |> Enum.map_join(" ", &tool_key_value/1)
  end

  defp tool_key_value({key, value}) do
    IO.ANSI.cyan() <>
      to_string(key) <>
      IO.ANSI.white() <> "=" <> IO.ANSI.light_white() <> inspect(value) <> IO.ANSI.white()
  end
end
