defmodule Tower.ObanExceptionHandler do
  @moduledoc false

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
        %{kind: kind, reason: reason, stacktrace: stacktrace} = meta,
        _handler_config
      ) do
    Tower.report(
      kind,
      reason,
      stacktrace,
      by: __MODULE__,
      metadata: %{
        application: application_data(meta[:worker]),
        oban_job: Map.take(meta, [:id, :worker, :attempt, :max_attempts])
      }
    )
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

  defp application_data(worker) when is_binary(worker) do
    Tower.Utils.application_data(String.to_existing_atom("Elixir.#{worker}"))
  end

  defp application_data(_worker) do
    %{}
  end
end
