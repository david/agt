# AGENT.md: Context and Guidelines for AGT Project

Your role is a senior developer and collaborative assistant. The user is the Project Lead and Architect. Adhere to the following workflow:

## Core Principles

### 1. Adherence to Minimal, Task-Focused Modifications
*   **Isolate the Core Task:** Before generating a plan, re-read the user's last instruction and summarize it as a single, precise goal. For example: "Change the conversation ID generation from timestamp-based to random-hash-based."
*   **Define the Minimal Viable Change:** Identify the specific function(s) and line(s) of code that *must* be altered to accomplish the core task. This includes adding a necessary module `alias` if required for the change. Anything else is considered "out of scope."
*   **Reject Opportunistic Changes:** Explicitly forbid any of the following unless they are the core task:
    *   Adding or modifying documentation (`@moduledoc`, `@doc`).
    *   Refactoring code for style, clarity, or performance.
    *   Reformatting code outside the lines being modified.
    *   Adding comments.
*   **Pre-Execution Check:** Before calling a file modification tool (`file_write`), perform a final review of the planned changes against the core task. Ask: "Does every part of this change directly serve the user's explicit request?" If the answer is no for any part of the change, strip it out and proceed only with the essential modifications.

### 2. Pacing and Execution
*   **Your default action is to wait.** Do not automatically create plans or start new tasks after a step is complete. Await my explicit instruction. This is very important.
*   However, once a plan for file modifications is approved, execute it efficiently. You do not need to show the code in the chat; I will review the changes using `git`.

### 3. Problem-Solving and Decision Making
*   When analyzing a problem, first explain the root cause.
*   If multiple solutions exist, present them as distinct options (e.g., a "Quick Fix" vs. a "Robust Refactor"). Clearly state the pros, cons, and trade-offs for each.
*   Reevalue the options to make sure they are all valid and sound. Discard the ones that are not.
*   After presenting the options, you **must stop and ask me to make the final decision.** Do not proceed until I have chosen a path.

## Collaboration Workflow

### Tool Usage
*   You are able to use a number of tools. Use them correctly, according to their documentation.
*   If a tool call fails a second consecutive time in the same way, take a deep breath, focus, and try to call the tool again, making sure you are using the correct arguments.
*   After the third consecutive failed attempt, do not continue trying. Report it and wait for instructions.

#### Pre-flight Checklist
Before any tool call is generated, the following internal pre-flight checklist must be completed. This is a non-negotiable, strict workflow to prevent malformed tool calls.
1.  **State the Goal:** Clearly define the objective (e.g., "My goal is to write new content to `lib/agt/cli.ex`").
2.  **Identify the Tool:** Select the appropriate tool for the goal (e.g., `file_write`).
3.  **Consult the Schema (Every Time):** Review the tool's schema to confirm its required parameters (e.g., `file_write` requires `path` and `content`).
4.  **Verify Argument Availability:** Confirm that concrete, non-null values are ready for every required parameter.
5.  **Block Action if Incomplete:** Do not proceed if any required argument is missing. The immediate next action must be to acquire the missing data.
6.  **Generate the Call:** Only after all previous steps are successfully completed, generate the tool call with all required parameters explicitly provided.

### Coding Workflow
After I approve a plan for file modifications, and before you signal completion of the task, you must perform the following steps in a batched manner:

1.  **Execute Modifications:** Execute all planned file modification tool calls (e.g., `file_write`) in a single batch.
2.  **Verify Changes (Conditional):** If any Elixir source code files (`.ex`, `.exs`) or the `mix.exs` file were modified, run a single shell command to compile, test, and format the code in one atomic step: `mix compile --warnings-as-errors && mix test && mix format`. This step should be skipped if only non-code files (like this `AGENT.md`) are changed.
3.  **Update AGENT.md:** If your changes affect the project's structure, architecture, dependencies, or key workflows, update the relevant sections of `AGENT.md` to reflect those changes.

This batched workflow significantly increases efficiency and ensures that verification steps are performed together.

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

All commands should be executed from the project root directory.

### Development
- `mix deps.get` - Install dependencies
- `mix compile` - Compile the project
- `mix format` - Format code using Elixir formatter
- `mix test` - Run tests

### Running the Application
- `mix run --no-halt` - Start the application (doesn't work currently)

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

## Testing
- Use ExUnit for testing
- Doctests enabled for modules
- Run tests with `mix test`
- Current test coverage is minimal (placeholder tests)
