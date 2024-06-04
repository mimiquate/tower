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

  def report_exception(exception, stacktrace, meta \\ %{})
      when is_exception(exception) and is_list(stacktrace) do
    reporters()
    |> Enum.each(fn reporter ->
      reporter.report_exception(exception, stacktrace, meta)
    end)
  end

  def report(type, reason, stacktrace, meta \\ %{})
      when is_atom(type) and is_binary(reason) and is_list(stacktrace) do
    reporters()
    |> Enum.each(fn reporter ->
      reporter.report(type, reason, stacktrace, meta)
    end)
  end

  def reporters do
    [
      Tower.EphemeralReporter
    ]
  end
end
