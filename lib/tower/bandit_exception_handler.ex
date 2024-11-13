defmodule Tower.BanditExceptionHandler do
  @moduledoc false

  require Logger

  @handler_id __MODULE__

  def attach do
    :telemetry.attach(
      @handler_id,
      [:bandit, :request, :exception],
      &__MODULE__.handle_event/4,
      _handler_config = []
    )
  end

  def detach do
    :telemetry.detach(@handler_id)
  end

  def handle_event(
        [:bandit, :request, :exception],
        _event_measurements,
        event_metadata,
        _handler_config
      ) do
    handle_event_metadata(event_metadata)
  end

  defp handle_event_metadata(%{
         # Not sure why bandit sends all exception with kind: :exit
         kind: :exit,
         exception: %{
           __struct__: Plug.Conn.WrapperError,
           kind: :error,
           reason: reason,
           stack: stacktrace,
           conn: conn
         },
         stacktrace: stacktrace
       }) do
    exception = Exception.normalize(:error, reason, stacktrace)

    if report?(exception) do
      Tower.report_exception(exception, stacktrace, plug_conn: conn)
    end
  end

  defp handle_event_metadata(%{
         kind: :exit,
         exception: reason,
         stacktrace: stacktrace,
         conn: conn
       })
       when is_exception(reason) do
    exception = Exception.normalize(:error, reason, stacktrace)

    if report?(exception) do
      Tower.report_exception(exception, stacktrace, plug_conn: conn)
    end
  end

  defp handle_event_metadata(event_metadata) do
    Logger.warning(
      "UNHANDLED BANDIT REQUEST EXCEPTION with event_metadata=#{inspect(event_metadata, pretty: true)}"
    )

    :ignored
  end

  defp report?(exception) do
    # TODO: Check bandit version =< 1.5.7 ?
    false &&
      Plug.Exception.status(exception) in 500..599
  end
end
