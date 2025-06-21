# CONTEXT and Guidelines for AGT Project

## Project Overview
AGT (AI Agent Tool) is an Elixir-based AI agent framework that provides a REPL interface for interacting with Google's Gemini API. The project creates conversational AI agents with persistent conversation storage and tool-using capabilities.

## Project Structure
```
agt/
├── lib/agt/                 # Core application modules
│   ├── agent.ex             # Main Agent GenServer
│   ├── agent_supervisor.ex  # Agent supervision
│   ├── application.ex       # OTP Application
│   ├── cli.ex               # Command line interface  
│   ├── config.ex            # Configuration management
│   ├── conversations.ex     # Conversation persistence
│   ├── gemini_client.ex     # Google Gemini API client
│   ├── message.ex           # Message structs
│   ├── repl.ex              # Interactive REPL
│   ├── session.ex           # Session management
│   └── tools/               # Tool modules
│       ├── file_delete.ex
│       ├── file_list.ex
│       ├── file_read.ex
│       └── file_write.ex
├── test/                    # Test files
└── mix.exs                  # Project configuration
```

## Key Commands

### Development
- `mix deps.get` - Install dependencies
- `mix compile` - Compile the project
- `mix format` - Format code using Elixir formatter
- `mix test` - Run tests
- `mix escript.build` - Build executable
- `./agt` - Run the built executable

### Running the Application
- `mix run --no-halt` - Start the application (doesn't work currently)
- `agt` - Start REPL (requires GEMINI_API_KEY environment variable)
- `agt --help` - Show help
- `agt --version` - Show version

## Code Style & Conventions

### Elixir Style
- Follow standard Elixir conventions
- Use `mix format` for consistent formatting
- Module documentation with `@moduledoc`
- Function documentation with `@doc` for public functions
- Use `alias` for module references
- Pattern matching for control flow

### Architecture Patterns
- **OTP Applications**: Main application uses Application behavior
- **GenServers**: Agents are implemented as GenServers for state management
- **Supervisors**: A `DynamicSupervisor` is used for agent supervision and fault tolerance.
- **Message Passing**: Communication via GenServer calls/casts

### Module Organization
- Modules are organized under `Agt` namespace
- Each module has a single responsibility
- Configuration isolated in `Agt.Config`
- API clients separated (e.g., `Agt.GeminiClient`)
- Tools are located in the `Agt.Tools` namespace.
- Session management is handled by `Agt.Session`.

## Dependencies
See `mix.exs` for dependencies.

## Key Design Patterns

### Agent Lifecycle
1. Agent started via `Agt.AgentSupervisor.start_agent()`
2. Conversations persisted to filesystem in `.agt/conversations/` directory
3. Each message timestamped and stored as JSON
4. Stateful conversation maintained in GenServer state

### Message Flow
1. User input → `Agt.Message.Prompt`
2. Stored to conversation
3. Sent to Gemini API via `Agt.GeminiClient`
4. Gemini API may respond with a request to call a function.
5. The tool is executed and the result is sent back to the Gemini API.
6. Response → `Agt.Message.Response`
7. Stored to conversation
8. Returned to user

### Error Handling
- Config validation for API keys
- HTTP request timeout handling
- Graceful API error responses
- File system error handling for conversation storage

## Testing
- Use ExUnit for testing
- Doctests enabled for modules
- Run tests with `mix test`
- Current test coverage is minimal (placeholder tests)

## Build & Distribution
- Escript enabled for CLI distribution
- Main module: `Agt.CLI`
- Executable built with `mix escript.build`

## Future Considerations
- Add comprehensive test coverage
- Add support for other LLM providers
- Enhance error handling and logging
- Add configuration file support
