defmodule AshTest do
  use ExUnit.Case

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    on_exit(fn ->
      Tower.EphemeralReporter.reset()
    end)
  end

  test "reports ash resource create exception" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        TestApp.Domain.User
        |> Ash.Changeset.for_create(:create)
        |> Ash.create!()
      end)
    end)

    assert_eventually(
      [
        %{
          level: :error,
          kind: :error,
          reason: %Ash.Error.Invalid{errors: [%Ash.Error.Changes.Required{field: :name}]},
          stacktrace: [_ | _],
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
