defmodule Agt.REPL.MarkdownRenderer do
  @moduledoc """
  Renders Markdown to a terminal-friendly format using ANSI escape codes.
  """

  alias IO.ANSI

  @doc """
  Renders a Markdown string to a terminal-formatted string.

  ## Examples

      iex> Agt.Markdown.Renderer.render("# Hello\\n\\n**Bold** and _italic_.")
      "\\e[36m# Hello\\e[0m\\n\\n\\e[1mBold\\e[0m and \\e[4mitalic\\e[0m."

  """
  def render(markdown) do
    {:ok, ast, _} = EarmarkParser.as_ast(markdown)

    ast
    |> Enum.map_join("\n", &to_ansi/1)
    |> IO.iodata_to_binary()
  end

  defp to_ansi({tag, _, children, _}) when tag in ["h1", "h2", "h3", "h4", "h5", "h6"] do
    [ANSI.cyan(), "\n# ", Enum.map(children, &to_ansi/1), ANSI.reset()]
  end

  defp to_ansi({"p", _, children, _}) do
    Enum.map(children, &to_ansi/1)
  end

  defp to_ansi({"strong", _, children, _}) do
    [ANSI.bright(), Enum.map(children, &to_ansi/1), ANSI.reset()]
  end

  defp to_ansi({"em", _, children, _}) do
    [ANSI.italic(), Enum.map(children, &to_ansi/1), ANSI.reset()]
  end

  defp to_ansi({"ul", _, items, _}) do
    items
    |> Enum.map(&to_ansi/1)
    |> Enum.map_join("\n", fn item -> "- " <> to_string(item) end)
  end

  defp to_ansi({"li", _, children, _}) do
    Enum.map(children, &to_ansi/1)
  end

  defp to_ansi({"pre", _, children, _}) do
    [ANSI.light_black(), Enum.map(children, &to_ansi/1), ANSI.reset()]
  end

  defp to_ansi({"code", _, children, _}) do
    Enum.map(children, &to_ansi/1)
  end

  defp to_ansi({tag, _, children, _}) do
    # Fallback for unhandled tags
    IO.warn("Unhandled Markdown tag: #{tag}")
    Enum.map(children, &to_ansi/1)
  end

  defp to_ansi(string) when is_binary(string) do
    string
  end
end
