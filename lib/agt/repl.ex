defmodule Agt.REPL do
  @moduledoc """
  Interactive REPL for chatting with the AI
  """

  alias Agt.{Config, GeminiClient}

  @prompt "You: "
  
  defp get_terminal_size do
    case :io.columns() do
      {:ok, cols} -> 
        case :io.rows() do
          {:ok, rows} -> {rows, cols}
          _ -> {24, 80}  # fallback
        end
      _ -> {24, 80}  # fallback
    end
  end

  defp setup_screen do
    IO.write(IO.ANSI.clear())
    IO.write(IO.ANSI.home())
  end

  defp position_prompt_at_bottom(rows) do
    IO.write(IO.ANSI.cursor(rows, 1))
    IO.write(IO.ANSI.clear_line())
    IO.write(@prompt)
  end

  defp scroll_content_up do
    IO.write("\n")
  end

  defp animate_thinking(_rows) do
    dots = [".", "..", "..."]
    
    Stream.cycle(dots)
    |> Enum.each(fn dot ->
      # Clear from current cursor position and write dots
      IO.write("\r")
      IO.write("AI: #{dot}")
      Process.sleep(1000)
    end)
  end

  def start do
    case Config.get_api_key() do
      {:ok, api_key} ->
        # Enable shell history and line editing
        Application.put_env(:stdlib, :shell_history, :enabled)
        setup_screen()
        IO.puts("AGT - AI Agent Tool")
        IO.puts("Type 'exit' or 'quit' to exit")
        IO.puts("")
        loop(api_key)

      {:error, error} ->
        IO.puts("Error: #{error}")
        IO.puts("Please set the GEMINI_API_KEY environment variable")
        System.halt(1)
    end
  end

  defp loop(api_key) do
    {rows, _cols} = get_terminal_size()
    position_prompt_at_bottom(rows)
    
    input = :io.get_line(:standard_io, "") |> to_string() |> String.trim()

    case input do
      input when input in ["exit", "quit", "q"] ->
        IO.write(IO.ANSI.cursor(rows - 1, 1))
        IO.puts("Goodbye!")

      "" ->
        loop(api_key)

      message ->
        # Move cursor up to write user message in conversation area
        IO.write(IO.ANSI.cursor(rows - 1, 1))
        IO.write(IO.ANSI.clear_line())
        IO.puts("You: #{message}")
        
        # Write AI response
        IO.write("AI: ")
        
        # Start animation task
        animation_task = Task.async(fn -> animate_thinking(rows) end)
        
        # Make API call
        result = GeminiClient.generate_content(message, api_key)
        
        # Stop animation
        Task.shutdown(animation_task, :brutal_kill)
        
        # Clear the dots and write response
        IO.write("\r")
        IO.write("AI: ")
        
        case result do
          {:ok, response} ->
            IO.puts(response)

          {:error, error} ->
            IO.puts("Error: #{error}")
        end

        scroll_content_up()
        loop(api_key)
    end
  end
end
