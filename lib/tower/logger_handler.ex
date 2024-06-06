defmodule Tower.LoggerHandler do
  @default_level :error
  @handler_id :tower

  def attach do
    :logger.add_handler(@handler_id, __MODULE__, %{level: @default_level})
  end

  def detach do
    :logger.remove_handler(@handler_id)
  end

  # :logger callbacks

  def adding_handler(config) do
    IO.puts("[Tower.LoggerHandler] ADDING config=#{inspect(config)}")

    {:ok, config}
  end

  def removing_handler(config) do
    IO.puts("[Tower.LoggerHandler] REMOVING config=#{inspect(config)}")

    :ok
  end

  # elixir 1.15+
  def log(%{level: :error, meta: %{crash_reason: {exception, stacktrace}} = meta}, _config)
      when is_exception(exception) and is_list(stacktrace) do
    IO.puts("[Tower.LoggerHandler] EXCEPTION #{inspect(exception)}")

    Tower.report_exception(exception, stacktrace, meta)
  end

  # elixir 1.15+
  def log(
        %{level: :error, meta: %{crash_reason: {{:nocatch, reason}, stacktrace}} = meta},
        _config
      )
      when is_list(stacktrace) do
    IO.puts("[Tower.LoggerHandler] NOCATCH #{inspect(reason)}")

    Tower.report(:nocatch, reason, stacktrace, meta)
  end

  # elixir 1.15+
  def log(%{level: :error, meta: %{crash_reason: {exit_reason, stacktrace}} = meta}, _config)
      when is_list(stacktrace) do
    IO.puts("[Tower.LoggerHandler] EXIT #{inspect(exit_reason)}")

    Tower.report(:exit, exit_reason, stacktrace, meta)
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
    Tower.report_exception(exception, stacktrace, meta)
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
    Tower.report(:nocatch, reason, stacktrace, meta)
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
        Tower.report(:exit, reason, stacktrace, meta)

      e when is_exception(e) ->
        Tower.report_exception(e, stacktrace, meta)

      _ ->
        Tower.report(:exit, reason, stacktrace, meta)
    end
  end

  def log(log_event, _config) do
    IO.puts(
      "[Tower.LoggerHandler] UNHANDLED LOG EVENT log_event=#{inspect(log_event, pretty: true)}"
    )
  end
end
