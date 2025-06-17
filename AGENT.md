# AGT Project Guidelines

## Project Overview
AGT (AI Agent Tool) is an Elixir-based AI agent framework that provides a REPL interface for interacting with Google's Gemini API. The project creates conversational AI agents with persistent conversation storage.

## Project Structure
```
agt/
├── lib/agt/              # Core application modules
│   ├── agent.ex         # Main Agent GenServer
│   ├── agent_supervisor.ex  # Agent supervision
│   ├── application.ex   # OTP Application
│   ├── cli.ex          # Command line interface  
│   ├── config.ex       # Configuration management
│   ├── conversations.ex # Conversation persistence
│   ├── gemini_client.ex # Google Gemini API client
│   ├── message.ex          # Message structs
│   └── repl.ex         # Interactive REPL
├── test/               # Test files
└── mix.exs           # Project configuration
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
- `mix run --no-halt` - Start the application
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
- **Supervisors**: Agent supervision for fault tolerance
- **Message Passing**: Communication via GenServer calls/casts

### Module Organization
- Modules are organized under `Agt` namespace
- Each module has a single responsibility
- Configuration isolated in `Agt.Config`
- API clients separated (e.g., `Agt.GeminiClient`)

## Dependencies
- **req** (~> 0.4.0) - HTTP client for API calls
- **jason** (~> 1.4) - JSON encoding/decoding

## Key Design Patterns

### Agent Lifecycle
1. Agent started via `Agt.AgentSupervisor.start_agent()`
2. Conversations persisted to filesystem in `conversations/` directory
3. Each message timestamped and stored as JSON
4. Stateful conversation maintained in GenServer state

### Message Flow
1. User input → `Operator.Message`
2. Stored to conversation
3. Sent to Gemini API via `GeminiClient`
4. Response → `LLM.Message`
5. Stored to conversation
6. Returned to user

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

## Docker Development
- Development environment containerized
- Hex packages cached in named volume
- Source code mounted for live development
- Environment variables passed through

## Build & Distribution
- Escript enabled for CLI distribution
- Main module: `Agt.CLI`
- Executable built with `mix escript.build`

## Future Considerations
- Add comprehensive test coverage
- Implement conversation loading/resumption
- Add support for other LLM providers
- Enhance error handling and logging
- Add configuration file support
