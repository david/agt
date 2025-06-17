defmodule Agt.LLM do
  defmodule Message do
    @derive {JSON.Encoder, only: [:body]}
    defstruct [:body]
  end
end
