defmodule TowerProcLibTest do
  use ExUnit.Case

  use AssertEventually, timeout: 500, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    new_config =
      Application.get_all_env(:logger)
      |> Keyword.put(:handle_sasl_reports, true)

    Application.put_all_env(logger: new_config)

    Logger.App.stop()

    # Shutdown the application
    Logger.App.stop()

    # And start it without warnings
    Application.put_env(:logger, :level, :error)
    Application.start(:logger)
    Application.delete_env(:logger, :level)
    Logger.configure(level: :debug)

    on_exit(fn ->
      Tower.EphemeralReporter.reset()
    end)
  end

  test "reports if proc lib crashes" do
    # capture_log(fn ->
      # in_unlinked_process(fn ->
        pid = TestProc.spawn_link()
        send(pid, :go)

        # ref = Process.monitor(pid)
        # send(pid, {:exit, "something"})
        # receive do: ({:DOWN, ^ref, _, _, _} -> :ok)
      # end)
    # end)

    assert_eventually(
      [
        %{
          level: :error,
          kind: :error,
          stacktrace: [],
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )
  end

  defp in_unlinked_process(fun) when is_function(fun, 0) do
    start_supervised(Task.Supervisor)
    |> case do
      {:ok, pid} ->
        Process.link(pid)
        pid

      {:error, {:already_started, pid}} ->
        pid
    end
    |> Task.Supervisor.async_nolink(fun)
    |> Task.yield()
  end

  defp reported_events do
    Tower.EphemeralReporter.events()
  end
end
