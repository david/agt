defmodule Agt.LLM do
  defmodule Message do
    @derive {JSON.Encoder, only: [:body]}
    defstruct [:body]
  end

  defmodule FunctionCall do
    @derive {JSON.Encoder, only: [:name, :arguments]}
    defstruct [:name, :arguments]
  end
end
