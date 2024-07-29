defmodule Tower.EphemeralReporter do
  @behaviour Tower.Reporter

  use Agent

  alias Tower.Event

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @impl true
  def report_event(%Event{
        kind: :error,
        reason: exception,
        stacktrace: stacktrace,
        log_event_meta: log_event_meta
      }) do
    add_error(exception.__struct__, Exception.message(exception), stacktrace, log_event_meta)
  end

  def report_event(%Event{
        kind: :exit,
        reason: reason,
        stacktrace: stacktrace,
        log_event_meta: log_event_meta
      }) do
    add_error(:exit, reason, stacktrace, log_event_meta)
  end

  def report_event(%Event{
        kind: :throw,
        reason: reason,
        stacktrace: stacktrace,
        log_event_meta: log_event_meta
      }) do
    add_error(:throw, reason, stacktrace, log_event_meta)
  end

  def report_event(%Event{
        kind: :message,
        level: level,
        reason: message,
        log_event_meta: log_event_meta
      }) do
    add(%{
      time: Map.get(log_event_meta, :time, :logger.timestamp()),
      level: level,
      kind: nil,
      reason: message,
      stacktrace: []
    })
  end

  def events do
    Agent.get(__MODULE__, & &1)
  end

  defp add_error(kind, reason, stacktrace, metadata) do
    add(%{
      time: Map.get(metadata, :time, :logger.timestamp()),
      level: :error,
      kind: kind,
      reason: reason,
      stacktrace: stacktrace
    })
  end

  defp add(event) when is_map(event) do
    Agent.update(__MODULE__, fn events -> [event | events] end)
  end
end
