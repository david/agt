defmodule Agt.Session.Marker do
  @moduledoc """
  Handles the file-based session marker used for recovering state after a crash.
  """

  @marker_path ".agt/active_session"

  def path, do: @marker_path

  def create(conversation_id) do
    # FIXME: If multiple instances of the app are started, this will overwrite the marker file.
    File.write!(@marker_path, conversation_id)

    conversation_id
  end

  def read do
    case File.read(@marker_path) do
      {:error, :enoent} ->
        nil

      {:ok, conversation_id} ->
        conversation_id
    end
  end

  def delete do
    if File.exists?(@marker_path) do
      File.rm!(@marker_path)
    end

    :ok
  end
end
