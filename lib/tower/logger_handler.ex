defmodule Tower.LoggerHandler do
  @default_log_level :critical
  @handler_id Tower
  @default_burst_limit_period 1
  @default_burst_limit_hits 10
  @own_logs_domain [:tower, :logger_handler]

  require Logger

  @spec attach() :: :ok | {:error, term()}
  @spec attach(Keyword.t()) :: :ok | {:error, term()}
  def attach(options \\ []) do
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
        ],
        config: %{
          burst_limit_period:
            Keyword.get(options, :burst_limit_period, @default_burst_limit_period),
          burst_limit_hits: Keyword.get(options, :burst_limit_hits, @default_burst_limit_hits)
        }
      }
    )
  end

  @spec detach() :: :ok | {:error, term()}
  def detach do
    :logger.remove_handler(@handler_id)
  end

  # :logger callbacks

  def adding_handler(%{config: config2} = config) do
    rate_limiter_init(config2)

    {:ok, config}
  end

  def removing_handler(_config) do
    rate_limiter_delete()

    :ok
  end

  def log(log_event, _config) do
    hit()
    |> case do
      :ok ->
        handle_log_event(log_event)

      {:error, expected_wait_time_in_ms} ->
        safe_log(
          :warning,
          "Tower.LoggerHandler burst limited, ignoring log event. Expected to resume in #{expected_wait_time_in_ms}ms."
        )

        :ignore
    end
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
    Application.get_env(:tower, :log_level, @default_log_level)
  end

  defp safe_log(level, message) do
    Logger.log(level, message, domain: @own_logs_domain)
  end

  defp hit do
    rate_limiter()
    |> RateLimiter.hit()
  end

  defp rate_limiter_init(%{
         burst_limit_period: burst_limit_period,
         burst_limit_hits: burst_limit_hits
       }) do
    RateLimiter.new(@handler_id, burst_limit_period, burst_limit_hits)
  end

  defp rate_limiter_delete do
    RateLimiter.delete(@handler_id)
  end

  defp rate_limiter do
    RateLimiter.get!(@handler_id)
  end
end
