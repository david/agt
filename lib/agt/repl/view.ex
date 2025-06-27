defmodule Agt.REPL.View do
  @moduledoc """
  Handles the presentation logic for the REPL.
  """

  @doc """
  Displays the provided prompt string to the console in bright white.
  """
  def display_prompt(prompt) do
    IO.write(IO.ANSI.light_white() <> prompt <> IO.ANSI.reset())
  end

  @doc """
  Clears the lines with the active prompt and reprints the submitted text
  in a muted historical style.
  """
  def reprint_historical_prompt(submitted_text, lines_to_clear) do
    IO.write(
      # Clear screen from cursor to end
      IO.ANSI.cursor_up(lines_to_clear) <>
        "\e[J" <>
        IO.ANSI.light_black() <>
        submitted_text <>
        IO.ANSI.reset() <>
        "\n"
    )
  end
end
