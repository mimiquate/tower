defmodule Tower.LoggerHandler do
  @moduledoc false

  @handler_id Tower
  @own_logs_domain [:tower, :logger_handler]

  require Logger

  @spec attach() :: :ok | {:error, term()}
  def attach do
    :logger.add_handler(
      @handler_id,
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
  def detach do
    :logger.remove_handler(@handler_id)
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

  # For Bandit < 1.6.2 which doesn't unwrap Plug.Conn.WrapperError
  defp handle_log_event(
         %{
           level: :error,
           meta: %{
             crash_reason: {
               %{
                 kind: :error,
                 reason: reason,
                 stack: stacktrace,
                 conn: conn
               },
               stacktrace
             }
           }
         } = log_event
       ) do
    Tower.report_exception(
      Exception.normalize(:error, reason, stacktrace),
      stacktrace,
      log_event: log_event,
      plug_conn: conn,
      by: __MODULE__
    )
  end

  defp handle_log_event(
         %{level: :error, meta: %{crash_reason: {exception, stacktrace}}} = log_event
       )
       when is_exception(exception) and is_list(stacktrace) do
    Tower.report_exception(exception, stacktrace, log_event: log_event, by: __MODULE__)
  end

  defp handle_log_event(
         %{level: :error, meta: %{crash_reason: {{:nocatch, reason}, stacktrace}}} = log_event
       )
       when is_list(stacktrace) do
    Tower.report_throw(reason, stacktrace, log_event: log_event, by: __MODULE__)
  end

  defp handle_log_event(
         %{level: :error, meta: %{crash_reason: {exit_reason, stacktrace}}} = log_event
       )
       when is_list(stacktrace) do
    report_exit(exit_reason, stacktrace, log_event)
  end

  # For Plug.Cowboy < 2.7.4 which didn't properly format the crash_reason as a two element tuple
  # Fixed in https://github.com/elixir-plug/plug_cowboy/pull/108
  defp handle_log_event(%{level: :error, meta: %{crash_reason: exit_reason}} = log_event) do
    report_exit(exit_reason, [], log_event)
  end

  defp handle_log_event(%{level: level, msg: {:string, reason_chardata}} = log_event) do
    if should_handle?(level) do
      report_message(level, IO.chardata_to_string(reason_chardata), log_event)
    end
  end

  defp handle_log_event(%{level: level, msg: {:report, report}} = log_event) do
    if should_handle?(level) do
      report_message(level, report, log_event)
    end
  end

  defp handle_log_event(%{level: level, msg: {format, args}} = log_event) when is_list(args) do
    if should_handle?(level) do
      report_message(level, formatted_message(format, args), log_event)
    end
  end

  defp handle_log_event(%{level: level} = log_event) do
    log_event_str = inspect(log_event, pretty: true)
    safe_log(:warning, "[Tower.LoggerHandler] UNRECOGNIZED LOG EVENT log_event=#{log_event_str}")

    if should_handle?(level) do
      Tower.report_message(
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

  defp report_exit(reason, stacktrace, log_event) do
    Tower.report_exit(reason, stacktrace, log_event: log_event, by: __MODULE__)
  end

  defp report_message(level, message, log_event) do
    Tower.report_message(level, message, log_event: log_event, by: __MODULE__)
  end

  defp log_level do
    # This config env can be to any of the 8 levels in https://www.erlang.org/doc/apps/kernel/logger#t:level/0,
    # or special values :all and :none.
    Application.fetch_env!(:tower, :log_level)
  end

  defp safe_log(level, message) do
    Logger.log(level, message, domain: @own_logs_domain)
  end

  defp formatted_message(format, args) do
    # Borrowed from Elixir's Logger.Formatter:
    # https://github.com/elixir-lang/elixir/blob/a4adaa871f1b65a166bce5d007ed5f34fd231fb9/lib/logger/lib/logger/formatter.ex#L273-L278

    format
    |> Logger.Utils.scan_inspect(args, log_messages_max_bytes())
    |> :io_lib.build_text()
    |> IO.chardata_to_string()
  end

  defp log_messages_max_bytes do
    Application.get_env(:logger, :truncate, 2048)
  end
end
