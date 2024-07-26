defmodule Tower.EphemeralReporter do
  @behaviour Tower.Handler

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @impl true
  def handle_event(%Tower.Event{
        kind: :exception,
        reason: exception,
        stacktrace: stacktrace,
        metadata: metadata
      }) do
    add_error(exception.__struct__, Exception.message(exception), stacktrace, metadata)
  end

  def handle_event(%Tower.Event{
        kind: kind,
        reason: reason,
        stacktrace: stacktrace,
        metadata: metadata
      })
      when kind in [:throw, :exit] do
    add_error(kind, reason, stacktrace, metadata)
  end

  def handle_event(%Tower.Event{
        kind: :message,
        level: level,
        reason: message,
        metadata: metadata
      }) do
    add(%{
      time: Map.get(metadata, :time, :logger.timestamp()),
      level: level,
      kind: nil,
      reason: message,
      stacktrace: []
    })
  end

  def events do
    Agent.get(__MODULE__, & &1)
  end

  defp add_error(kind, reason, stacktrace, %{log_event: %{meta: log_event_meta}}) do
    add(%{
      time: Map.get(log_event_meta, :time, :logger.timestamp()),
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
