defmodule Agt.Conversations do
  @moduledoc """
  Conversations storage
  """

  @path ".agt/conversations"

  def list_messages(conversation_id) do
    path = Path.join(@path, conversation_id)

    if File.dir?(path) do
      path
      |> File.ls!()
      |> Enum.sort()
      |> Stream.map(&Path.join(path, &1))
      |> Stream.map(&read_message/1)
      |> Enum.reverse()
    else
      []
    end
  end

  def create_message(message, conversation_id) do
    iodata = JSON.encode_to_iodata!(message)

    [@path, conversation_id]
    |> Path.join()
    |> File.mkdir_p!()

    write_message(iodata, conversation_id)

    {:ok, message}
  end

  defp read_message(path) do
    path
    |> File.read!()
    |> JSON.decode!()
    |> then(&(&1 |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end) |> Map.new()))
    |> structify()
  end

  defp structify(%{type: "prompt"} = map), do: struct(Agt.Message.UserMessage, map)
  defp structify(%{type: "response"} = map), do: struct(Agt.Message.ModelMessage, map)
  defp structify(%{type: "function_call"} = map), do: struct(Agt.Message.FunctionCall, map)

  defp structify(%{type: "function_response"} = map),
    do: struct(Agt.Message.FunctionResponse, map)

  defp write_message(iodata, conversation_id) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    write_message(iodata, conversation_id, timestamp)
  end

  defp write_message(iodata, conversation_id, timestamp, retry_number \\ 0) do
    counter = retry_number |> to_string() |> String.pad_leading(2, "0")
    message_id = "#{timestamp}#{counter}"

    case write_file(iodata, conversation_id, message_id) do
      :ok ->
        :ok

      {:error, :eexist} ->
        write_message(iodata, conversation_id, timestamp, retry_number + 1)
    end
  end

  defp write_file(message, conversation_id, message_id) do
    path = Path.join([@path, conversation_id, "#{message_id}.json"])

    if File.exists?(path) do
      {:error, :eexist}
    else
      File.write(path, message)
    end
  end
end
