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
      metadata: %{application: application_data(meta[:worker])}
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
    case :application.get_application(String.to_existing_atom("Elixir.#{worker}")) do
      {:ok, app_name} ->
        case :application.get_key(app_name, :vsn) do
          {:ok, app_version} when is_list(app_version) ->
            %{name: app_name, version: List.to_string(app_version)}

          _ ->
            %{name: app_name}
        end

      :undefined ->
        %{}
    end
  end

  defp application_data(_worker) do
    %{}
  end
end
