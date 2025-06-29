defmodule Agt.REPL.PromptTest do
  use ExUnit.Case, async: true

  alias Agt.REPL.Prompt

  describe "format/3" do
    test "formats the full prompt string with ruler, tokens, and OSC sequences" do
      total_tokens = 1234
      max_tokens = 5000
      columns = 80

      total_tokens_str = Integer.to_string(total_tokens)
      max_tokens_display = Integer.to_string(max_tokens)
      token_display_base_len = 7

      token_display_length =
        token_display_base_len + String.length(total_tokens_str) +
          String.length(max_tokens_display)

      ruler_length = columns
      remaining_space = ruler_length - token_display_length
      left_dashes = Float.floor(remaining_space / 2) |> trunc()
      right_dashes = Float.ceil(remaining_space / 2) |> trunc()
      token_display = "┤ 󰃬 #{total_tokens_str}/#{max_tokens_display} ├"

      expected_ruler_part =
        String.duplicate("─", left_dashes) <> token_display <> String.duplicate("─", right_dashes)

      expected_prompt =
        "\e]133;A\a" <>
          IO.ANSI.light_black() <>
          expected_ruler_part <>
          "\n" <>
          " " <> "\e]133;B\a"

      {:ok, actual_prompt} = Prompt.format(total_tokens, max_tokens, columns)

      assert actual_prompt == expected_prompt
    end

    test "formats the full prompt string when max_tokens is :unknown" do
      total_tokens = 500
      max_tokens = :unknown
      columns = 80

      total_tokens_str = Integer.to_string(total_tokens)
      max_tokens_display = "∞"
      token_display_base_len = 7

      token_display_length =
        token_display_base_len + String.length(total_tokens_str) +
          String.length(max_tokens_display)

      ruler_length = columns
      remaining_space = ruler_length - token_display_length
      left_dashes = Float.floor(remaining_space / 2) |> trunc()
      right_dashes = Float.ceil(remaining_space / 2) |> trunc()
      token_display = "┤ 󰃬 #{total_tokens_str}/#{max_tokens_display} ├"

      expected_ruler_part =
        String.duplicate("─", left_dashes) <> token_display <> String.duplicate("─", right_dashes)

      expected_prompt =
        "\e]133;A\a" <>
          IO.ANSI.light_black() <>
          expected_ruler_part <>
          "\n" <>
          " " <> "\e]133;B\a"

      {:ok, actual_prompt} = Prompt.format(total_tokens, max_tokens, columns)

      assert actual_prompt == expected_prompt
    end

    test "returns an error for column widths that are too small for the full prompt" do
      total_tokens = 10
      max_tokens = 100
      columns = 10

      assert Prompt.format(total_tokens, max_tokens, columns) ==
               {:error, :column_width_too_small}
    end

    test "handles zero total tokens in the full prompt string" do
      total_tokens = 0
      max_tokens = 500
      columns = 80

      total_tokens_str = Integer.to_string(total_tokens)
      max_tokens_display = Integer.to_string(max_tokens)
      token_display_base_len = 7

      token_display_length =
        token_display_base_len + String.length(total_tokens_str) +
          String.length(max_tokens_display)

      ruler_length = columns
      remaining_space = ruler_length - token_display_length
      left_dashes = Float.floor(remaining_space / 2) |> trunc()
      right_dashes = Float.ceil(remaining_space / 2) |> trunc()
      token_display = "┤ 󰃬 #{total_tokens_str}/#{max_tokens_display} ├"

      expected_ruler_part =
        String.duplicate("─", left_dashes) <> token_display <> String.duplicate("─", right_dashes)

      expected_prompt =
        "\e]133;A\a" <>
          IO.ANSI.light_black() <>
          expected_ruler_part <>
          "\n" <>
          " " <> "\e]133;B\a"

      {:ok, actual_prompt} = Prompt.format(total_tokens, max_tokens, columns)
      assert actual_prompt == expected_prompt
    end

    test "handles large token counts in the full prompt string" do
      total_tokens = 99999
      max_tokens = 100_000
      columns = 80

      total_tokens_str = Integer.to_string(total_tokens)
      max_tokens_display = Integer.to_string(max_tokens)
      token_display_base_len = 7

      token_display_length =
        token_display_base_len + String.length(total_tokens_str) +
          String.length(max_tokens_display)

      ruler_length = columns
      remaining_space = ruler_length - token_display_length
      left_dashes = Float.floor(remaining_space / 2) |> trunc()
      right_dashes = Float.ceil(remaining_space / 2) |> trunc()
      token_display = "┤ 󰃬 #{total_tokens_str}/#{max_tokens_display} ├"

      expected_ruler_part =
        String.duplicate("─", left_dashes) <> token_display <> String.duplicate("─", right_dashes)

      expected_prompt =
        "\e]133;A\a" <>
          IO.ANSI.light_black() <>
          expected_ruler_part <>
          "\n" <>
          " " <> "\e]133;B\a"

      {:ok, actual_prompt} = Prompt.format(total_tokens, max_tokens, columns)
      assert actual_prompt == expected_prompt
    end
  end

  describe "format_fallback/0" do
    test "returns the correct fallback prompt string" do
      expected_fallback_prompt = "\e]133;A\a" <> IO.ANSI.light_black() <> "─ REPL ─\n" <> " " <> "\e]133;B\a"
      assert Prompt.format_fallback() == expected_fallback_prompt
    end
  end

  describe "format_end_prompt/0" do
    test "returns the correct end-of-prompt marker string" do
      expected_end_prompt = IO.ANSI.reset() <> "\e]133;C\a" <> "\n" <> "..."
      assert Prompt.format_end_prompt() == expected_end_prompt
    end
  end
end
