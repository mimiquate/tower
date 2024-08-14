defmodule Tower.ObanExceptionHandler do
  require Logger

  @handler_id __MODULE__

  def attach do
    :telemetry.attach(
      @handler_id,
      [:oban, :job, :exception],
      &__MODULE__.handle_event/4,
      _handler_config = []
    )
  end

  def detach do
    :telemetry.detach(@handler_id)
  end

  def handle_event(
        [:oban, :job, :exception],
        _event_measurements,
        %{kind: kind, reason: reason, stacktrace: stacktrace},
        _handler_config
      ) do
    Tower.handle_caught(kind, reason, stacktrace)
  end

  def handle_event(
        [:oban, :job, :exception],
        _event_measurementes,
        event_metadata,
        _handler_config
      ) do
    Logger.warning(
      "UNHANDLED OBAN JOB EXCEPTION with event_metadata=#{inspect(event_metadata, pretty: true)}"
    )

    :ignored
  end
end
