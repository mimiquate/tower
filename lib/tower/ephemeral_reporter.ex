defmodule Tower.EphemeralReporter do
  @behaviour Tower.Reporter

  use Agent

  alias Tower.Event

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @impl true
  def report_event(%Event{
        id: id,
        time: time,
        kind: :error,
        reason: exception,
        stacktrace: stacktrace,
        metadata: metadata
      }) do
    add_error(id, time, exception.__struct__, Exception.message(exception), stacktrace, metadata)
  end

  def report_event(%Event{
        id: id,
        time: time,
        kind: :exit,
        reason: reason,
        stacktrace: stacktrace,
        metadata: metadata
      }) do
    add_error(id, time, :exit, reason, stacktrace, metadata)
  end

  def report_event(%Event{
        id: id,
        time: time,
        kind: :throw,
        reason: reason,
        stacktrace: stacktrace
      }) do
    add_error(id, time, :throw, reason, stacktrace)
  end

  def report_event(%Event{
        id: id,
        time: time,
        kind: :message,
        level: level,
        reason: message,
        metadata: metadata
      }) do
    add(%{
      id: id,
      time: time,
      level: level,
      kind: nil,
      reason: message,
      stacktrace: [],
      metadata: metadata
    })
  end

  def events do
    Agent.get(__MODULE__, & &1)
  end

  defp add_error(id, time, kind, reason, stacktrace, metadata \\ %{}) do
    add(%{
      id: id,
      time: time,
      level: :error,
      kind: kind,
      reason: reason,
      stacktrace: stacktrace,
      metadata: metadata
    })
  end

  defp add(event) when is_map(event) do
    Agent.update(__MODULE__, fn events -> [event | events] end)
  end
end
