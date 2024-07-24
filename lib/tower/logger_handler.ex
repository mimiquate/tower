defmodule Tower.LoggerHandler do
  @default_log_level :critical
  @handler_id Tower

  def attach do
    :logger.add_handler(@handler_id, __MODULE__, %{level: :all})
  end

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

  # elixir 1.15+
  def log(%{level: :error, meta: %{crash_reason: {exception, stacktrace}} = meta}, _config)
      when is_exception(exception) and is_list(stacktrace) do
    %Tower.Event{
      exception: exception,
      stacktrace: stacktrace,
      log_event_meta: meta
    }
    |> Tower.handle_event()
  end

  # elixir 1.15+
  def log(
        %{level: :error, meta: %{crash_reason: {{:nocatch, reason}, stacktrace}} = meta},
        _config
      )
      when is_list(stacktrace) do
    Tower.handle_throw(reason, stacktrace, meta)
  end

  # elixir 1.15+
  def log(%{level: :error, meta: %{crash_reason: {exit_reason, stacktrace}} = meta}, _config)
      when is_list(stacktrace) do
    Tower.handle_exit(exit_reason, stacktrace, meta)
  end

  # elixir 1.14
  def log(
        %{
          level: :error,
          msg: {:report, %{report: %{reason: {exception, stacktrace}}}},
          meta: meta
        },
        _config
      )
      when is_exception(exception) and is_list(stacktrace) do
    Tower.handle_exception(exception, stacktrace, meta)
  end

  # elixir 1.14
  def log(
        %{
          level: :error,
          msg: {:report, %{report: %{reason: {{:nocatch, reason}, stacktrace}}}},
          meta: meta
        },
        _config
      )
      when is_list(stacktrace) do
    Tower.handle_throw(reason, stacktrace, meta)
  end

  # elixir 1.14
  def log(
        %{
          level: :error,
          msg: {:report, %{report: %{reason: {reason, stacktrace}}}},
          meta: meta
        },
        _config
      )
      when is_list(stacktrace) do
    case Exception.normalize(:error, reason) do
      %ErlangError{} ->
        Tower.handle_exit(reason, stacktrace, meta)

      e when is_exception(e) ->
        Tower.handle_exception(e, stacktrace, meta)

      _ ->
        Tower.handle_exit(reason, stacktrace, meta)
    end
  end

  def log(%{level: level, msg: {:string, reason_chardata}, meta: meta}, _config) do
    if should_handle?(level) do
      Tower.handle_message(level, IO.chardata_to_string(reason_chardata), meta)
    end
  end

  def log(%{level: level, msg: {:report, report}, meta: meta}, _config) do
    if should_handle?(level) do
      Tower.handle_message(level, report, meta)
    end
  end

  def log(log_event, _config) do
    IO.puts(
      "[Tower.LoggerHandler] UNHANDLED LOG EVENT log_event=#{inspect(log_event, pretty: true)}"
    )
  end

  defp should_handle?(level) do
    :logger.compare_levels(level, log_level()) in [:gt, :eq]
  end

  defp log_level do
    # This config env can be to any of the 8 levels in https://www.erlang.org/doc/apps/kernel/logger#t:level/0,
    # or special values :all and :none.
    Application.get_env(:tower, :log_level, @default_log_level)
  end
end
