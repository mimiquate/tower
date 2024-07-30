defmodule Tower do
  @moduledoc """
  Documentation for `Tower`.
  """

  alias Tower.Event

  @default_reporters [Tower.EphemeralReporter]

  def attach do
    :ok = Tower.LoggerHandler.attach()
  end

  def detach do
    :ok = Tower.LoggerHandler.detach()
  end

  def handle_exception(exception, stacktrace, meta)
      when is_exception(exception) and is_list(stacktrace) do
    Event.from_exception(exception, stacktrace, meta)
    |> report_event()
  end

  def handle_throw(reason, stacktrace, metadata) do
    Event.from_throw(reason, stacktrace, metadata)
    |> report_event()
  end

  def handle_exit(reason, stacktrace, metadata) do
    Event.from_exit(reason, stacktrace, metadata)
    |> report_event()
  end

  def handle_message(level, message, metadata \\ %{}) do
    Event.from_message(level, message, metadata)
    |> report_event()
  end

  defp report_event(%Event{} = event) do
    each_reporter(fn reporter ->
      reporter.report_event(event)
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
