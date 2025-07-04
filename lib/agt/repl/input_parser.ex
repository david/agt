defmodule Agt.REPL.InputParser do
  @moduledoc """
  Parses user input, determining single-line or multi-line modes
  and extracting the final prompt content.
  """

  @multiline_marker_regex_start ~r{^\s*\|}
  @multiline_marker_regex_end ~r{[|:]\s*$}

  @doc """
  Parses the first line of user input to determine the input mode.

  Returns:
  - {:single_line, prompt_string} if it's a single line prompt.
  - {:multi_line_start, initial_line_content} if it triggers multi-line input.
  - :ignore if the input should be ignored (e.g., empty line).
  """
  def parse_first_line(line) do
    stripped_line = String.trim_trailing(line, "\n")

    cond do
      String.match?(stripped_line, @multiline_marker_regex_start) ->
        processed_line = String.trim_leading(stripped_line, "|")
        {:multi_line_start, processed_line}

      String.match?(stripped_line, @multiline_marker_regex_end) ->
        processed_line = String.trim_trailing(stripped_line, "|")
        {:multi_line_start, processed_line}

      true ->
        final_prompt = String.trim(stripped_line)
        if final_prompt == "", do: :ignore, else: {:single_line, final_prompt}
    end
  end

  @doc """
  Processes a continuation line in multi-line input mode.

  Returns:
  - {:continue, updated_lines} if more lines are expected.
  - {:finished, final_prompt_string} if multi-line input is terminated.
  """
  def parse_continuation_line(line, current_lines) do
    stripped_line = String.trim_trailing(line, "\n")

    if stripped_line == "." do
      # Termination condition met
      {:finished, finalize_prompt(Enum.reverse(current_lines))}
    else
      # Continue collecting lines
      {:continue, [stripped_line | current_lines]}
    end
  end

  # Helper to finalize the prompt, applying final trim and checking for :ignore
  defp finalize_prompt(collected_lines) do
    final_prompt = Enum.join(collected_lines, "\n") |> String.trim()
    if final_prompt == "", do: :ignore, else: final_prompt
  end
end
