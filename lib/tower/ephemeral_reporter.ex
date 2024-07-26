defmodule Tower.EphemeralReporter do
  @behaviour Tower.Handler

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @impl true
  def handle_event(%Tower.Event{
        time: time,
        kind: :error,
        reason: exception,
        stacktrace: stacktrace
      }) do
    add_error(time, exception.__struct__, Exception.message(exception), stacktrace)
  end

  def handle_event(%Tower.Event{
        time: time,
        kind: kind,
        reason: reason,
        stacktrace: stacktrace
      })
      when kind in [:throw, :exit] do
    add_error(time, kind, reason, stacktrace)
  end

  def handle_event(%Tower.Event{
        time: time,
        kind: :message,
        level: level,
        reason: message
      }) do
    add(%{
      time: time,
      level: level,
      kind: nil,
      reason: message,
      stacktrace: []
    })
  end

  def events do
    Agent.get(__MODULE__, & &1)
  end

  defp add_error(time, kind, reason, stacktrace) do
    add(%{
      time: time,
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
