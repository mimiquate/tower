defmodule Tower do
  @moduledoc """
  Documentation for `Tower`.
  """

  alias Tower.Event

  @default_reporters [Tower.EphemeralReporter]

  @spec attach() :: :ok
  def attach do
    :ok = Tower.LoggerHandler.attach()
  end

  @spec detach() :: :ok
  def detach do
    :ok = Tower.LoggerHandler.detach()
  end

  @spec handle_caught(Exception.kind(), Event.reason(), Exception.stacktrace()) :: :ok
  @spec handle_caught(Exception.kind(), Event.reason(), Exception.stacktrace(), Keyword.t()) ::
          :ok
  def handle_caught(kind, reason, stacktrace, options \\ []) do
    Event.from_caught(kind, reason, stacktrace, options)
    |> report_event()
  end

  @spec handle_exception(Exception.t(), Exception.stacktrace()) :: :ok
  @spec handle_exception(Exception.t(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_exception(exception, stacktrace, options \\ [])
      when is_exception(exception) and is_list(stacktrace) do
    Event.from_exception(exception, stacktrace, options)
    |> report_event()
  end

  @spec handle_throw(term(), Exception.stacktrace()) :: :ok
  @spec handle_throw(term(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_throw(reason, stacktrace, options \\ []) do
    Event.from_throw(reason, stacktrace, options)
    |> report_event()
  end

  @spec handle_exit(term(), Exception.stacktrace()) :: :ok
  @spec handle_exit(term(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_exit(reason, stacktrace, options \\ []) do
    Event.from_exit(reason, stacktrace, options)
    |> report_event()
  end

  @spec handle_message(:logger.level(), term()) :: :ok
  @spec handle_message(:logger.level(), term(), Keyword.t()) :: :ok
  def handle_message(level, message, options \\ []) do
    Event.from_message(level, message, options)
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
