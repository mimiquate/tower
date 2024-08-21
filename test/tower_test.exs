defmodule TowerTest do
  use ExUnit.Case
  doctest Tower

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    start_reporter()
    Tower.attach(burst_limit_period: 10, burst_limit_hits: 1)

    on_exit(fn ->
      Tower.detach()
    end)
  end

  test "starts with 0 exceptions" do
    assert [] = reported_events()
  end

  test "reports arithmetic error" do
    captured_log =
      capture_log(fn ->
        in_unlinked_process(fn ->
          1 / 0
        end)

        in_unlinked_process(fn ->
          1 / 0
        end)
      end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{message: "bad argument in arithmetic expression"},
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
    assert captured_log =~ "[warning] Tower.LoggerHandler burst limited, ignoring log event"
  end

  test "reports a raise" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        raise "error inside process"
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "error inside process"},
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "reports a thrown string" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        throw("error")
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :throw,
          reason: "error",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "reports a thrown non-string" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        throw(something: "here")
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :throw,
          reason: [something: "here"],
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "doesn't report an normal exit" do
    in_unlinked_process(fn ->
      exit(:normal)
    end)

    assert [] = reported_events()
  end

  test "reports an abnormal exit" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        exit(:abnormal)
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "reports a kill exit" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        exit(:kill)
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :exit,
          reason: :kill,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "doesn't report a Logger.error by default" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        require Logger
        Logger.error("Something went wrong here")
      end)
    end)

    assert [] = reported_events()
  end

  test "reports a Logger.error (if enabled)" do
    put_env(:log_level, :error)

    in_unlinked_process(fn ->
      require Logger

      capture_log(fn ->
        Logger.error("Something went wrong here")
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :message,
          reason: "Something went wrong here",
          stacktrace: nil
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports a Logger.error (if enabled) with charlist" do
    put_env(:log_level, :error)

    in_unlinked_process(fn ->
      require Logger

      capture_log(fn ->
        Logger.error([
          "Postgrex.Protocol",
          32,
          40,
          "#PID<0.2612.0>",
          ") disconnected: " | "** (DBConnection.ConnectionError) tcp recv (idle): closed"
        ])
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :message,
          reason:
            "Postgrex.Protocol (#PID<0.2612.0>) disconnected: ** (DBConnection.ConnectionError) tcp recv (idle): closed",
          stacktrace: nil
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports a Logger structured report" do
    in_unlinked_process(fn ->
      require Logger

      capture_log(fn ->
        Logger.critical(something: :reported, this: :critical)
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :critical,
          kind: :message,
          reason: [something: :reported, this: :critical],
          stacktrace: nil
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports message manually" do
    Tower.handle_message(:info, "Something interesting", metadata: %{something: "else"})

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :info,
          kind: :message,
          reason: "Something interesting",
          stacktrace: nil,
          metadata: %{
            something: "else"
          }
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports Exception manually" do
    in_unlinked_process(fn ->
      try do
        1 / 0
      catch
        kind, reason ->
          Tower.handle_caught(kind, reason, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{message: "bad argument in arithmetic expression"},
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "reports Exception manually (shorthand)" do
    in_unlinked_process(fn ->
      try do
        1 / 0
      rescue
        e ->
          Tower.handle_exception(e, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{message: "bad argument in arithmetic expression"},
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "manually reports a thrown string" do
    in_unlinked_process(fn ->
      try do
        throw("error")
      catch
        kind, reason ->
          Tower.handle_caught(kind, reason, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          datetime: datetime,
          level: :error,
          kind: :throw,
          reason: "error",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "manually reports a thrown string (shorthand)" do
    in_unlinked_process(fn ->
      try do
        throw("error")
      catch
        x ->
          Tower.handle_throw(x, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :throw,
          reason: "error",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "manually reports an abnormal exit" do
    in_unlinked_process(fn ->
      try do
        exit(:abnormal)
      catch
        kind, reason ->
          Tower.handle_caught(kind, reason, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          datetime: datetime,
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  test "manually reports an abnormal exit (shorthand)" do
    in_unlinked_process(fn ->
      try do
        exit(:abnormal)
      catch
        :exit, reason ->
          Tower.handle_exit(reason, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
  end

  defp in_unlinked_process(fun) when is_function(fun, 0) do
    {:ok, pid} = Task.Supervisor.start_link()

    pid
    |> Task.Supervisor.async_nolink(fun)
    |> Task.yield()
  end

  defp start_reporter do
    Tower.EphemeralReporter.start_link([])
  end

  defp reported_events do
    Tower.EphemeralReporter.events()
  end

  defp put_env(key, value) do
    original_value = Application.get_env(:tower, key)
    Application.put_env(:tower, key, value)

    on_exit(fn ->
      if original_value == nil do
        Application.delete_env(:tower, key)
      else
        Application.put_env(:tower, key, original_value)
      end
    end)
  end

  defp recent_datetime?(datetime) do
    diff =
      :logger.timestamp()
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.diff(datetime, :microsecond)

    diff >= 0 && diff < 100_000
  end
end
