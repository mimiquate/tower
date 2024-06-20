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

  def report_exception(exception, stacktrace, meta \\ %{})
      when is_exception(exception) and is_list(stacktrace) do
    each_reporter(fn reporter ->
      reporter.report_exception(exception, stacktrace, meta)
    end)
  end

  def report_term(term, metadata \\ %{}) do
    each_reporter(fn reporter ->
      reporter.report_term(term, metadata)
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
