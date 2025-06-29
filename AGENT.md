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
1.  **Session Management (`Agt.Session`)**: The `Agt.Session` GenServer is the primary entry point for managing the agent's lifecycle. It is responsible for:
    *   Starting and supervising the `Agt.Agent` process using `Agt.AgentSupervisor`.
    *   Reading and applying the `AGENT.md` file content as a system prompt at startup.
    *   Handling session markers via `Agt.Session.Marker` to support crash recovery and resume previous conversations. A marker file (`.agt/active_session`) stores the `conversation_id` of the active session.
    *   Providing client API for prompting the agent (`Agt.Session.prompt/1`) and resetting the session (`Agt.Session.reset/1`).
2.  **Agent Process (`Agt.Agent`)**: The `Agt.Agent` GenServer holds the state of a single AI agent conversation. Key responsibilities include:
    *   Maintaining the conversation history (`messages`).
    *   Interacting with the `Agt.GeminiClient` to send messages to the Gemini API and receive responses.
    *   Storing conversation messages persistently using `Agt.Conversations`.
    *   Tracking token usage for the conversation.
3.  **Conversation Persistence (`Agt.Conversations`)**:
    *   Conversations are persisted to the filesystem in the `.agt/conversations/` directory.
    *   Each message is timestamped and stored as a separate JSON file within a conversation-specific subdirectory. This ensures a chronological and recoverable conversation history.

### Message Flow
The communication between the user, the agent, and the Gemini API follows a well-defined flow:

1.  **User Input**: User input is received by the REPL and converted into an `Agt.Message.Prompt` struct.
2.  **Message Storage**: The `Agt.Message.Prompt` is immediately stored to the conversation history via `Agt.Conversations.create_message/2`.
3.  **Gemini API Request**: The `Agt.Agent` collects the current conversation history and the system prompt, then sends it to the Gemini API using `Agt.GeminiClient.generate_content/2`.
4.  **Gemini API Response Processing**:
    *   The Gemini API responds with either a text-based message (`Agt.Message.Response`) or a request to execute a tool function (`Agt.Message.FunctionCall`).
    *   If a `FunctionCall` is received, the agent invokes the specified tool function (see "Tooling Integration" below).
    *   The result of the tool execution is then sent back to the Gemini API as an `Agt.Message.FunctionResponse`.
    *   This cycle (Gemini API -> Tool Call -> Gemini API with Tool Result) can repeat until the Gemini API provides a final text response.
5.  **Response Storage**: The final `Agt.Message.Response` (or `FunctionCall`/`FunctionResponse` during tool use) is stored to the conversation history.
6.  **Return to User**: The agent's response is returned to the user through the REPL.

### Tooling Integration
1.  **Tool Definition**: Tools are defined as Elixir modules under the `Agt.Tools` namespace (e.g., `Agt.Tools.FileRead`). Each tool module implements:
    *   `name/0`: Returns the string name of the tool.
    *   `meta/0`: Returns a map describing the tool's capabilities and expected arguments, following the Gemini API's function declaration format.
    *   `call/1`: Executes the tool's logic, accepting a map of arguments.
2.  **Tool Listing**: The `Agt.Tools` module provides `list/0` to retrieve a list of all available tool modules.
3.  **Tool Execution**: When the Gemini API requests a tool call, `Agt.Tools.call/2` is used to dynamically dispatch the call to the appropriate tool module, passing the provided arguments. The result of the tool execution is then incorporated back into the conversation with the Gemini API.

### Error Handling
*   **Configuration Validation**: `Agt.Config` handles validation of environment variables like `GEMINI_API_KEY`.
*   **HTTP Request Handling**: `Agt.GeminiClient` handles HTTP request timeouts and gracefully processes various API error responses (e.g., malformed function calls, network issues).
*   **File System Errors**: `Agt.Conversations` and `Agt.Session.Marker` include error handling for file system operations, such as directory creation and file read/write operations.
*   **GenServer Supervision**: The use of `DynamicSupervisor` (`Agt.AgentSupervisor`) ensures fault tolerance. If an `Agt.Agent` process crashes, it can be restarted, and the session can be recovered using the session marker.

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
