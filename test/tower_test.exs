defmodule TowerTest do
  use ExUnit.Case
  doctest Tower

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    start_reporter()
    Tower.attach()

    on_exit(fn ->
      Tower.detach()
    end)
  end

  test "starts with 0 exceptions" do
    assert [] = reported_events()
  end

  test "reports arithmetic error" do
    capture_log(fn ->
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
  end

  test "doesn't report an normal exit" do
    in_unlinked_process(fn ->
      exit(:normal)
    end)

    assert [] = reported_events()
  end

  test "doesn't report an shutdown exit" do
    in_unlinked_process(fn ->
      exit(:shutdown)
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
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
    assert [_ | _] = stacktrace
  end

  test "manually ignores normal exits (shorthand)" do
    in_unlinked_process(fn ->
      try do
        exit(:normal)
      catch
        :exit, reason when not Tower.is_normal_exit(reason) ->
          Tower.handle_exit(reason, __STACKTRACE__)
      end
    end)

    in_unlinked_process(fn ->
      try do
        exit(:shutdown)
      catch
        :exit, reason when not Tower.is_normal_exit(reason) ->
          Tower.handle_exit(reason, __STACKTRACE__)
      end
    end)

    in_unlinked_process(fn ->
      try do
        exit({:shutdown, 0})
      catch
        :exit, reason when not Tower.is_normal_exit(reason) ->
          Tower.handle_exit(reason, __STACKTRACE__)
      end
    end)

    assert [] = reported_events()
  end

  test "manually reports an abnormal exit (shorthand)" do
    in_unlinked_process(fn ->
      try do
        exit(:abnormal)
      catch
        :exit, reason when not Tower.is_normal_exit(reason) ->
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
    assert [_ | _] = stacktrace
  end

  test "bug in one reporter doesn't affect other reporters" do
    defmodule BuggyReporter do
      @behaviour Tower.Reporter

      @impl true
      def report_event(_event) do
        raise "I have a bug"
      end
    end

    put_env(:reporters, [BuggyReporter, Tower.EphemeralReporter])

    capture_log(fn ->
      in_unlinked_process(fn ->
        1 / 0
      end)
    end)

    assert_eventually(
      [
        %{
          id: id1,
          datetime: datetime1,
          level: :error,
          kind: :error,
          reason: %Tower.ReportEventError{
            reporter: BuggyReporter,
            original: {:error, %RuntimeError{message: "I have a bug"}, [_ | _]}
          },
          stacktrace: stacktrace1
        },
        %{
          id: id2,
          datetime: datetime2,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{message: "bad argument in arithmetic expression"},
          stacktrace: stacktrace2
        }
      ] = reported_events()
    )

    assert String.length(id1) == 36
    assert recent_datetime?(datetime1)
    assert is_list(stacktrace1)
    assert String.length(id2) == 36
    assert recent_datetime?(datetime2)
    assert is_list(stacktrace2)
    assert datetime1 > datetime2
  end

  test "protects reporters from repeated events" do
    capture_log(fn ->
      for _ <- 1..2 do
        in_unlinked_process(fn ->
          1 / 0
        end)
      end

      in_unlinked_process(fn ->
        raise "something else"
      end)
    end)

    assert_eventually(
      [
        %{
          similarity_id: other_similarity_id,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "something else"}
        },
        %{
          similarity_id: similarity_id,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{message: "bad argument in arithmetic expression"}
        },
        %{
          similarity_id: similarity_id,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{message: "bad argument in arithmetic expression"}
        }
      ] = reported_events()
    )

    assert similarity_id != other_similarity_id
  end

  test "doesn't report ignored exceptions" do
    put_env(:ignored_exceptions, [ArithmeticError])

    capture_log(fn ->
      in_unlinked_process(fn ->
        1 / 0
      end)

      in_unlinked_process(fn ->
        raise "error"
      end)
    end)

    assert_eventually(
      [
        %{
          kind: :error,
          reason: %RuntimeError{message: "error"}
        }
      ] = reported_events()
    )
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
