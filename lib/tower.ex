defmodule Tower do
  @moduledoc """
  Documentation for `Tower`.
  """

  @default_handlers [Tower.EphemeralReporter]

  def attach do
    :ok = Tower.LoggerHandler.attach()
  end

  def detach do
    :ok = Tower.LoggerHandler.detach()
  end

  def handle_event(event) do
    each_handler(fn handler ->
      handler.handle_event(event)
    end)
  end

  defp each_handler(fun) when is_function(fun, 1) do
    handlers()
    |> Enum.each(fn handler ->
      async(fn ->
        fun.(handler)
      end)
    end)
  end

  def handlers do
    Application.get_env(:tower, :handlers, @default_handlers)
  end

  defp async(fun) do
    Tower.TaskSupervisor
    |> Task.Supervisor.start_child(fun)
  end
end
