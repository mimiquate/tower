defmodule Tower.LoggerHandler do
  @moduledoc false

  @default_handler_id __MODULE__
  @own_logs_domain [:tower, :logger_handler]

  require Logger

  @spec attach() :: :ok | {:error, term()}
  def attach(handler_id \\ @default_handler_id) do
    :logger.add_handler(
      handler_id,
      __MODULE__,
      %{
        level: :all,
        filters: [
          own_logs_filter: {
            &:logger_filters.domain/2,
            {:stop, :sub, [:elixir | @own_logs_domain]}
          }
        ]
      }
    )
  end

  @spec detach() :: :ok | {:error, term()}
  def detach(handler_id \\ @default_handler_id) do
    :logger.remove_handler(handler_id)
  end

  # :logger callbacks

  def adding_handler(config) do
    {:ok, config}
  end

  def removing_handler(_config) do
    :ok
  end

  def log(log_event, _config) do
    handle_log_event(log_event)
  end

  defp handle_log_event(
         %{level: :error, meta: %{crash_reason: {exception, stacktrace}}} = log_event
       )
       when is_exception(exception) and is_list(stacktrace) do
    Tower.handle_exception(exception, stacktrace, log_event: log_event)
  end

  defp handle_log_event(
         %{level: :error, meta: %{crash_reason: {{:nocatch, reason}, stacktrace}}} = log_event
       )
       when is_list(stacktrace) do
    Tower.handle_throw(reason, stacktrace, log_event: log_event)
  end

  defp handle_log_event(
         %{level: :error, meta: %{crash_reason: {exit_reason, stacktrace}}} = log_event
       )
       when is_list(stacktrace) do
    Tower.handle_exit(exit_reason, stacktrace, log_event: log_event)
  end

  defp handle_log_event(%{level: :error, meta: %{crash_reason: exit_reason}} = log_event) do
    Tower.handle_exit(exit_reason, [], log_event: log_event)
  end

  defp handle_log_event(%{level: level, msg: {:string, reason_chardata}} = log_event) do
    if should_handle?(level) do
      Tower.handle_message(level, IO.chardata_to_string(reason_chardata), log_event: log_event)
    end
  end

  defp handle_log_event(%{level: level, msg: {:report, report}} = log_event) do
    if should_handle?(level) do
      Tower.handle_message(level, report, log_event: log_event)
    end
  end

  defp handle_log_event(%{level: level} = log_event) do
    log_event_str = inspect(log_event, pretty: true)
    safe_log(:warning, "[Tower.LoggerHandler] UNRECOGNIZED LOG EVENT log_event=#{log_event_str}")

    if should_handle?(level) do
      Tower.handle_message(
        level,
        "Unrecognized log event",
        log_event: log_event,
        metadata: %{log_event: log_event_str}
      )
    end
  end

  defp should_handle?(level) do
    Tower.equal_or_greater_level?(level, log_level())
  end

  defp log_level do
    # This config env can be to any of the 8 levels in https://www.erlang.org/doc/apps/kernel/logger#t:level/0,
    # or special values :all and :none.
    Application.fetch_env!(:tower, :log_level)
  end

  defp safe_log(level, message) do
    Logger.log(level, message, domain: @own_logs_domain)
  end
end
