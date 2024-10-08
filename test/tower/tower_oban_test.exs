defmodule TowerObanTest do
  use ExUnit.Case
  doctest Tower

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    start_link_supervised!({
      TestApp.Repo,
      database: "tmp/test-#{:rand.uniform(10_000)}.db", journal_mode: :memory
    })

    start_link_supervised!(
      {Oban, engine: Oban.Engines.Lite, repo: TestApp.Repo, queues: [default: 10]}
    )

    capture_log(fn ->
      Ecto.Migrator.up(TestApp.Repo, 0, TestApp.Repo.Migrations.AddOban)
    end)

    on_exit(fn ->
      Tower.EphemeralReporter.reset()
    end)
  end

  test "reports raised exception in an Oban worker" do
    TestApp.RuntimeErrorWorker.new(%{}, max_attempts: 1)
    |> Oban.insert()

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "error from an Oban worker"},
          stacktrace: stacktrace,
          captured_by: Tower.ObanExceptionHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  test "reports uncaught throw generated in an Oban worker" do
    TestApp.UncaughtThrowWorker.new(%{}, max_attempts: 1)
    |> Oban.insert()

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %Oban.CrashError{reason: "something"},
          stacktrace: stacktrace,
          captured_by: Tower.ObanExceptionHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  test "reports abnormal exit generated in an Oban worker" do
    TestApp.AbnormalExitWorker.new(%{}, max_attempts: 1)
    |> Oban.insert()

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %Oban.CrashError{reason: :abnormal},
          stacktrace: stacktrace,
          captured_by: Tower.ObanExceptionHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  defp recent_datetime?(datetime) do
    diff =
      :logger.timestamp()
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.diff(datetime, :microsecond)

    diff >= 0 && diff < 100_000
  end
end
