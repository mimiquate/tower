defmodule Tower do
  @moduledoc """
  Documentation for `Tower`.
  """

  @default_reporters [Tower.EphemeralReporter]

  def attach do
    :ok = Tower.LoggerHandler.attach()
  end

  def detach do
    :ok = Tower.LoggerHandler.detach()
  end

  def handle_event(%Tower.Event{
        exception: exception,
        stacktrace: stacktrace,
        log_event_meta: meta
      }) do
    each_reporter(fn reporter ->
      reporter.report_exception(exception, stacktrace, meta)
    end)
  end

  def handle_exception(exception, stacktrace, meta \\ %{})
      when is_exception(exception) and is_list(stacktrace) do
    each_reporter(fn reporter ->
      reporter.report_exception(exception, stacktrace, meta)
    end)
  end

  def handle_throw(reason, stacktrace, metadata \\ %{}) do
    each_reporter(fn reporter ->
      reporter.report_throw(reason, stacktrace, metadata)
    end)
  end

  def handle_exit(reason, stacktrace, metadata \\ %{}) do
    each_reporter(fn reporter ->
      reporter.report_exit(reason, stacktrace, metadata)
    end)
  end

  def handle_message(level, message, metadata \\ %{}) do
    each_reporter(fn reporter ->
      reporter.report_message(level, message, metadata)
    end)
  end

  defp each_reporter(fun) when is_function(fun, 1) do
    reporters()
    |> Enum.each(fn reporter ->
      async(fn ->
        fun.(reporter)
      end)
    end)
  end

  def reporters do
    Application.get_env(:tower, :reporters, @default_reporters)
  end

  defp async(fun) do
    Tower.TaskSupervisor
    |> Task.Supervisor.start_child(fun)
  end
end
