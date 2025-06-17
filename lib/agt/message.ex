defmodule Agt.Message do
  defmodule Prompt do
    @derive {JSON.Encoder, only: [:body]}
    defstruct [:body]
  end

  defmodule Response do
    @derive {JSON.Encoder, only: [:body]}
    defstruct [:body]
  end

  defmodule FunctionCall do
    @derive {JSON.Encoder, only: [:name, :arguments]}
    defstruct [:name, :arguments]
  end

  defmodule FunctionResponse do
    @derive {JSON.Encoder, only: [:name, :result]}
    defstruct [:name, :result]
  end
end
