defmodule Tower do
  @moduledoc """
  Documentation for `Tower`.
  """

  def attach do
    :ok = Tower.LoggerHandler.attach()
  end

  def detach do
    :ok = Tower.LoggerHandler.detach()
  end

  def report_exception(exception, stacktrace, meta \\ %{}) do
    reporters()
    |> Enum.each(fn reporter ->
      reporter.report_exception(exception, stacktrace, meta)
    end)
  end

  def reporters do
    [
      Tower.EphemeralReporter
    ]
  end
end
