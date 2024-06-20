defmodule Tower.EphemeralReporter do
  @behaviour Tower.Reporter

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @impl true
  def report_exception(exception, stacktrace, metadata \\ %{})
      when is_exception(exception) and is_list(stacktrace) do
    Agent.update(
      __MODULE__,
      fn errors ->
        [
          %{
            time: Map.get(metadata, :time, :logger.timestamp()),
            type: exception.__struct__,
            reason: Exception.message(exception),
            stacktrace: stacktrace
          }
          | errors
        ]
      end
    )
  end

  @impl true
  def report_term(reason, metadata \\ %{}) do
    Agent.update(
      __MODULE__,
      fn events ->
        [
          %{
            time: Map.get(metadata, :time, :logger.timestamp()),
            type: Map.get(metadata, :type),
            reason: reason,
            stacktrace: Map.get(metadata, :stacktrace, [])
          }
          | events
        ]
      end
    )
  end

  # def report_error(type, reason, stacktrace, metadata \\ %{}) when is_atom(type) and is_list(stacktrace) do
  #   Agent.update(
  #     __MODULE__,
  #     fn events ->
  #       [
  #         %{
  #           time: Map.get(metadata, :time, :logger.timestamp()),
  #           type: type,
  #           reason: reason,
  #           stacktrace: stacktrace
  #         }
  #         | events
  #       ]
  #     end
  #   )
  # end

  def errors do
    Agent.get(__MODULE__, & &1)
  end
end
