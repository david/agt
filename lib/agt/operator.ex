defmodule Agt.Operator do
  defmodule Message do
    @derive {JSON.Encoder, only: [:body]}
    defstruct [:body]
  end

  defmodule FunctionResponse do
    @derive {JSON.Encoder, only: [:name, :result]}
    defstruct [:name, :result]
  end
end
