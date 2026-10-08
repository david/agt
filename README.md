# Agt

AGT (AI Agent Tool) is an AI coding assistant that runs in your terminal,
written in Elixir. You talk to it at an interactive prompt, it sends the
conversation to Google's Gemini API, and the model can act on your project
through built-in tools: reading, writing, listing and deleting files, and
running shell commands.

Conversations are saved so they persist between sessions, the model's Markdown
replies are rendered in the terminal, and the prompt shows token usage.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `agt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agt, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/agt>.

