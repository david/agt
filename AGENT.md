# AGT - AI Agent Tool

Command line AI agent tool written in Elixir for chatting with Google Gemini.

## Quick Start

```bash
# Set API key
export GEMINI_API_KEY="your_api_key_here"

# Install dependencies (may need erlang-dev package)
mix deps.get

# Build executable
mix escript.build

# Run interactive REPL
./agt

# Show help
./agt --help
```

## Project Structure

```
lib/
├── agt.ex                 # Main module (unused)
├── agt/
│   ├── cli.ex            # Command line interface and argument parsing
│   ├── config.ex         # Configuration management (API keys)
│   ├── gemini_client.ex  # Google Gemini API client
│   └── repl.ex           # Interactive REPL loop
```

## Key Commands

- **Build**: `mix escript.build`
- **Dependencies**: `mix deps.get`
- **Test**: `mix test`
- **Format**: `mix format`

## Configuration

- **GEMINI_API_KEY**: Required environment variable for Google Gemini API access
- **Model**: Uses `gemini-2.5-pro-preview-06-05`
- **Timeout**: 30 seconds for API requests

## Dependencies

- **req**: HTTP client for API requests
- **jason**: JSON encoding/decoding

## REPL Commands

- `exit`, `quit`, `q`: Exit the REPL
- Empty input: Ignored, continues loop
- Any other text: Sent to Gemini API

## Architecture

- **CLI module**: Entry point, handles arguments
- **Config module**: Environment variable management
- **GeminiClient module**: API integration with error handling
- **REPL module**: Interactive loop with user I/O

## Notes

- Uses escript for standalone executable
- Stateless request/response model
- Basic error handling for API failures
- Simple synchronous operation
