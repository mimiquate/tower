defmodule TowerObanTest do
  use ExUnit.Case
  doctest Tower

  use AssertEventually, timeout: 100, interval: 10

  setup do
    start_link_supervised!(Tower.EphemeralReporter)

    start_link_supervised!({
      TestApp.Repo,
      database: "tmp/test-#{:rand.uniform(10_000)}.db", journal_mode: :memory
    })

    start_link_supervised!(
      {Oban, engine: Oban.Engines.Lite, repo: TestApp.Repo, queues: [default: 10]}
    )

    Ecto.Migrator.up(TestApp.Repo, 0, TestApp.Repo.Migrations.AddOban)

    Tower.attach()

    on_exit(fn ->
      Tower.detach()
    end)
  end

  @tag capture_log: true
  test "reports raised exception in an Oban worker" do
    TestApp.ArithmeticErrorWorker.new(%{}, max_attempts: 1)
    |> Oban.insert()

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "error from an Oban worker"},
          stacktrace: stacktrace
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
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
          stacktrace: stacktrace
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
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
          stacktrace: stacktrace
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  defp recent_datetime?(datetime) do
    diff =
      :logger.timestamp()
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.diff(datetime, :microsecond)

    diff >= 0 && diff < 100_000
  end
end
