defmodule Tower.EphemeralReporter do
  @behaviour Tower.Reporter

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @impl true
  def report_exception(exception, stacktrace, meta \\ %{})
      when is_exception(exception) and is_list(stacktrace) do
    Agent.update(
      __MODULE__,
      fn errors ->
        [
          %{
            time: Map.get(meta, :time, :logger.timestamp()),
            type: exception.__struct__,
            reason: Exception.message(exception),
            stacktrace: stacktrace
          }
          | errors
        ]
      end
    )
  end

  def report(type, reason, stacktrace, meta \\ %{}) when is_atom(type) and is_list(stacktrace) do
    Agent.update(
      __MODULE__,
      fn errors ->
        [
          %{
            time: Map.get(meta, :time, :logger.timestamp()),
            type: type,
            reason: reason,
            stacktrace: stacktrace
          }
          | errors
        ]
      end
    )
  end

  def errors do
    Agent.get(__MODULE__, & &1)
  end
end
