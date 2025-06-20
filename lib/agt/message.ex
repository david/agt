defmodule Agt.Message do
  defmodule Prompt do
    @derive {JSON.Encoder, only: [:body, :role, :type]}
    defstruct [:body, role: "user", type: "prompt"]
  end

  defmodule Response do
    @derive {JSON.Encoder, only: [:body, :role, :type]}
    defstruct [:body, role: "model", type: "response"]
  end

  defmodule FunctionCall do
    @derive {JSON.Encoder, only: [:name, :arguments, :role, :type]}
    defstruct [:name, :arguments, role: "model", type: "function_call"]
  end

  defmodule FunctionResponse do
    @derive {JSON.Encoder, only: [:name, :result, :role, :type]}
    defstruct [:name, :result, role: "user", type: "function_response"]
  end
end
