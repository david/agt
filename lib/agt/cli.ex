defmodule Agt.CLI do
  @moduledoc """
  Command line interface for AGT
  """

  alias Agt.REPL

  def main(args) do
    case args do
      [] ->
        # No arguments - start REPL
        REPL.start()

      ["--help"] ->
        print_help()

      ["-h"] ->
        print_help()

      ["--version"] ->
        print_version()

      ["-v"] ->
        print_version()

      _ ->
        IO.puts("Unknown arguments: #{Enum.join(args, " ")}")
        print_help()
        System.halt(1)
    end
  end

  defp print_help do
    IO.puts("""
    AGT - AI Agent Tool

    Usage:
      agt           Start interactive REPL
      agt --help    Show this help message
      agt --version Show version information

    Environment Variables:
      GEMINI_API_KEY  Required. Your Google Gemini API key
    """)
  end

  defp print_version do
    {:ok, version} = :application.get_key(:agt, :vsn)
    IO.puts("AGT version #{version}")
  end
end
