defmodule Agt.Conversations do
  @moduledoc """
  Conversations storage
  """

  def create_message(message, conversation_id) do
    File.mkdir_p!("conversations/#{conversation_id}")

    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    path = "conversations/#{conversation_id}/#{timestamp}.json"

    if File.exists?(path) do
      {:error, "Message exists: #{path}"}
    else
      iodata = JSON.encode_to_iodata!(message)
      :ok = File.write(path, iodata)

      {:ok, message}
    end
  end
end
