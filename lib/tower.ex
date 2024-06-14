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
    reporters()
    |> Enum.each(fn reporter ->
      async(fn ->
        IO.inspect(self())
        reporter.report_exception(exception, stacktrace, meta)
      end)
    end)
  end

  def report(type, reason, stacktrace, meta \\ %{}) when is_atom(type) and is_list(stacktrace) do
    reporters()
    |> Enum.each(fn reporter ->
      async(fn ->
        reporter.report(type, reason, stacktrace, meta)
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
