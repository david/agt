defmodule Agt.Message do
  @moduledoc """
  Defines the message structs used for communication between the user, the model, and tools.
  """

  defmodule UserMessage do
    @moduledoc """
    Represents a message from the user.
    """
    @derive {JSON.Encoder, only: [:body, :role, :type]}
    defstruct [:body, role: "user", type: "prompt"]
  end

  defmodule ModelMessage do
    @moduledoc """
    Represents a message from the model.
    """
    @derive {JSON.Encoder, only: [:body, :role, :type]}
    defstruct [:body, role: "model", type: "response"]
  end

  defmodule FunctionCall do
    @moduledoc """
    Represents a function call requested by the model.
    """
    @derive {JSON.Encoder, only: [:name, :arguments, :role, :type]}
    defstruct [:name, :arguments, role: "model", type: "function_call"]
  end

  defmodule FunctionResponse do
    @moduledoc """
    Represents the result of a function call.
    """
    @derive {JSON.Encoder, only: [:name, :result, :role, :type]}
    defstruct [:name, :result, role: "user", type: "function_call_output"]
  end
end
