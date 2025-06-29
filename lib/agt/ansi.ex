
defmodule Agt.ANSI do
  @moduledoc """
  Provides ANSI escape codes for terminal manipulation, specifically for
  prompt demarcation as defined by iTerm2's Shell Integration.
  """

  @doc """
  Returns the ANSI code for the start of a prompt.
  This is typically used at the beginning of a command line prompt.
  """
  def prompt_start(), do: "\e]133;A\a"

  @doc """
  Returns the ANSI code for the start of a command input.
  This is used right before the user's input area.
  """
  def command_start(), do: "\e]133;B\a"

  @doc """
  Returns the ANSI code for the end of a command output.
  This is used after a command has finished executing and its output is displayed.
  """
  def command_end(), do: "\e]133;C\a"
end
