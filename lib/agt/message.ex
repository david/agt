defmodule Agt.Message do
  defmodule Prompt do
    @derive {JSON.Encoder, only: [:body, :role]}
    defstruct [:body, role: "user"]
  end

  defmodule Response do
    @derive {JSON.Encoder, only: [:body, :role]}
    defstruct [:body, role: "model"]
  end

  defmodule FunctionCall do
    @derive {JSON.Encoder, only: [:name, :arguments, :role]}
    defstruct [:name, :arguments, role: "model"]
  end

  defmodule FunctionResponse do
    @derive {JSON.Encoder, only: [:name, :result, :role]}
    defstruct [:name, :result, role: "user"]
  end
end
