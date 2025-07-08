defmodule Agt.REPL.Prompt do
  @moduledoc """
  Handles the generation of the REPL prompt, including the ruler and token display.
  """

  @prompt_char " "

  @doc """
  Formats the REPL prompt string.

  It generates a ruler line with token information and prepares the chevron prompt.

  ## Parameters:
    - `total_tokens`: The current total number of tokens in the conversation.
    - `max_tokens`: The maximum allowed tokens for the conversation, or `:unknown`.
    - `columns`: The number of columns available in the terminal.

  ## Returns:
    A string containing the full formatted prompt with ANSI codes.
  """
  def format(total_tokens, max_tokens, columns) do
    # Convert tokens to string for length calculation
    total_tokens_str = Integer.to_string(total_tokens)

    max_tokens_display =
      case max_tokens do
        :unknown -> "∞"
        limit -> Integer.to_string(limit)
      end

    # Calculate the minimum length required for the token display part:
    # "┤ 󰃬 / ├" (fixed 7 chars) + total_tokens_str length + max_tokens_display length
    # Note: "󰃬" is a single codepoint, but takes 2 bytes, String.length counts codepoints.
    # The literal parts "┤ ", " 󰃬 ", "/", " ├" sum up to 2 + 2 + 1 + 2 = 7 characters.
    token_display_base_len = 7

    token_display_length =
      token_display_base_len + String.length(total_tokens_str) + String.length(max_tokens_display)

    # A ruler needs at least 2 dashes (one on each side) plus the token_display_length
    min_required_columns = token_display_length + 2

    if columns < min_required_columns do
      {:error, :column_width_too_small}
    else
      token_display = "┤ 󰃬 #{total_tokens_str}/#{max_tokens_display} ├"

      # The ruler_length is simply the columns available as we fill it entirely
      ruler_length = columns
      remaining_space = ruler_length - token_display_length

      left_dashes = Float.floor(remaining_space / 2) |> trunc()
      right_dashes = Float.ceil(remaining_space / 2) |> trunc()

      ruler_line =
        String.duplicate("─", left_dashes) <> token_display <> String.duplicate("─", right_dashes)

      # Construct the full prompt string including ANSI codes
      full_prompt =
        Agt.ANSI.prompt_start() <>
          IO.ANSI.light_black() <>
          ruler_line <>
          "\n" <>
          @prompt_char <> Agt.ANSI.command_start()

      {:ok, full_prompt}
    end
  end

  @doc """
  Formats a simple fallback REPL prompt for terminals with insufficient column width.
  """
  def format_fallback() do
    Agt.ANSI.prompt_start() <>
      IO.ANSI.light_black() <> "─ REPL ─\n" <> @prompt_char <> Agt.ANSI.command_start()
  end

  @doc """
  Formats the end-of-prompt marker.
  """
  def format_end_prompt() do
    IO.ANSI.reset() <> Agt.ANSI.command_end()
  end
end
