defmodule Agt.REPL.Editor do
  @moduledoc """
  Handles the REPL user input, including multi-line editing and prompt display.
  """

  alias Agt.REPL.InputParser
  alias Agt.REPL.Prompt

  @doc """
  Displays a prompt, reads user input (single or multi-line), and returns it.
  """
  def read(agent_meta) do
    IO.puts("")
    begin_prompt(agent_meta)

    # Read the first line of input
    first_line = IO.gets("")

    case InputParser.parse_first_line(first_line) do
      {:single_line, prompt} ->
        end_prompt()
        prompt

      {:multi_line_start, initial_line_content} ->
        # Start collecting multi-line input
        case collect_multi_line([initial_line_content]) do
          :ignore ->
            :ignore

          prompt ->
            end_prompt()
            prompt
        end

      :ignore ->
        :ignore
    end
  end

  defp collect_multi_line(current_lines) do
    # No prompt for continuation lines
    line = IO.gets("")

    case InputParser.parse_continuation_line(line, current_lines) do
      {:continue, updated_lines} ->
        collect_multi_line(updated_lines)

      {:finished, final_prompt} ->
        final_prompt
    end
  end

  defp begin_prompt(%{total_tokens: total_tokens, max_tokens: max_tokens}) do
    {:ok, columns} = :io.columns()

    case Prompt.format(total_tokens, max_tokens, columns) do
      {:ok, prompt_string} ->
        IO.write(prompt_string)

      {:error, :column_width_too_small} ->
        # Fallback for very small terminals where ruler cannot be displayed
        IO.write(Prompt.format_fallback())
    end
  end

  defp end_prompt() do
    IO.write(Prompt.format_end_prompt())
  end
end
