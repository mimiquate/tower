defmodule TowerTest do
  use ExUnit.Case
  doctest Tower

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    on_exit(fn ->
      Tower.EphemeralReporter.reset()
    end)
  end

  test "starts with 0 exceptions" do
    assert [] = reported_events()
  end

  test "reports runtime error" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        raise "an error"
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "an error"},
          stacktrace: stacktrace,
          metadata: %{pid: _},
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  test "reports as an :error an Erlang error Elixir can normalize" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        :erlang.error(:badarith)
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

  test "reports as an :exit an Erlang error Elixir cannot normalize" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        :erlang.error("a naked erlang error")
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          # Why ends up as exit?
          # https://github.com/elixir-lang/elixir/blob/78f63d08313677a680868685701ae79a2459dcc1/lib/logger/lib/logger/translator.ex#L663-L665
          kind: :exit,
          reason: "a naked erlang error",
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
          stacktrace: stacktrace,
          by: Tower.LoggerHandler
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

  test "doesn't report a normal exit" do
    in_unlinked_process(fn ->
      exit(:normal)
    end)

    assert [] = reported_events()
  end

  test "doesn't report a shutdown exit" do
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
          stacktrace: stacktrace,
          by: Tower.LoggerHandler
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
          stacktrace: stacktrace,
          by: Tower.LoggerHandler
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
          stacktrace: nil,
          by: Tower.LoggerHandler
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
          stacktrace: nil,
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports a Logger report list" do
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
          reason: "[something: :reported, this: :critical]",
          stacktrace: nil,
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports a Logger report map (as a list as Elixir's Logger)" do
    in_unlinked_process(fn ->
      require Logger

      capture_log(fn ->
        Logger.critical(%{one: 1, two: 2})
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :critical,
          kind: :message,
          reason: "[one: 1, two: 2]",
          stacktrace: nil,
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports a Logger format/args message" do
    in_unlinked_process(fn ->
      capture_log(fn ->
        :logger.critical(~c"This is a format with ~b ~p", [2, :args])
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :critical,
          kind: :message,
          reason: "This is a format with 2 :args",
          stacktrace: nil,
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports a legacy Erlang's error_logger:error_msg (if enabled)" do
    put_env(:log_level, :error)

    in_unlinked_process(fn ->
      capture_log(fn ->
        :error_logger.error_msg("An error occurred in ~p", [:some_module])
      end)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :message,
          reason: "An error occurred in :some_module",
          stacktrace: nil,
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports message manually" do
    Tower.report_message(:info, "Something interesting", metadata: %{something: "else"})

    assert(
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
          },
          by: nil
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
  end

  test "reports Exception manually" do
    in_unlinked_process(fn ->
      try do
        raise "an error"
      catch
        kind, reason ->
          Tower.report(kind, reason, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "an error"},
          stacktrace: stacktrace,
          by: nil
        }
      ] = reported_events()
    )

    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  test "reports Exception manually (shorthand)" do
    in_unlinked_process(fn ->
      try do
        raise "an error"
      rescue
        e ->
          Tower.report_exception(e, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "an error"},
          stacktrace: stacktrace,
          by: nil
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
          Tower.report(kind, reason, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          datetime: datetime,
          level: :error,
          kind: :throw,
          reason: "error",
          stacktrace: stacktrace,
          by: nil
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
          Tower.report_throw(x, __STACKTRACE__)
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
          stacktrace: stacktrace,
          by: nil
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
          Tower.report(kind, reason, __STACKTRACE__)
      end
    end)

    assert_eventually(
      [
        %{
          datetime: datetime,
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: stacktrace,
          by: nil
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
          Tower.report_exit(reason, __STACKTRACE__)
      end
    end)

    in_unlinked_process(fn ->
      try do
        exit(:shutdown)
      catch
        :exit, reason when not Tower.is_normal_exit(reason) ->
          Tower.report_exit(reason, __STACKTRACE__)
      end
    end)

    in_unlinked_process(fn ->
      try do
        exit({:shutdown, 0})
      catch
        :exit, reason when not Tower.is_normal_exit(reason) ->
          Tower.report_exit(reason, __STACKTRACE__)
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
          Tower.report_exit(reason, __STACKTRACE__)
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
          stacktrace: stacktrace,
          by: nil
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  test "allows reporting an existing Tower.Event struct" do
    id = "123"
    datetime = DateTime.utc_now()
    reason = "Something went wrong"

    %Tower.Event{
      id: id,
      datetime: datetime,
      level: :error,
      kind: :throw,
      reason: reason
    }
    |> Tower.report()

    assert [%{id: ^id, datetime: ^datetime, level: :error, kind: :throw, reason: ^reason}] =
             reported_events()
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
        raise "an error"
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
          stacktrace: stacktrace1,
          by: Tower.LoggerHandler
        },
        %{
          id: id2,
          datetime: datetime2,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "an error"},
          stacktrace: stacktrace2,
          by: Tower.LoggerHandler
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
          raise "an error"
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
          reason: %RuntimeError{message: "an error"}
        },
        %{
          similarity_id: similarity_id,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "an error"}
        }
      ] = reported_events()
    )

    assert similarity_id != other_similarity_id
  end

  test "doesn't report ignored exceptions" do
    put_env(:ignored_exceptions, [ArithmeticError])

    capture_log(fn ->
      in_unlinked_process(fn ->
        # Manually generate bad arithmetic error without compiler warnings would be
        # caused if using `1 / 0`.
        exit(:badarith)
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

  test "reports logger metadata" do
    put_env(:logger_metadata, [:user_id])

    capture_log(fn ->
      in_unlinked_process(fn ->
        Logger.metadata(user_id: 123, secret: "secret")

        raise "an error"
      end)
    end)

    assert_eventually(
      [
        %{
          kind: :error,
          reason: %RuntimeError{message: "an error"},
          metadata: %{user_id: 123}
        }
      ] = reported_events()
    )
  end

  @tag skip:
         Version.match?(System.version(), "< 1.17.0") or
           String.to_integer(System.otp_release()) < 27
  test "reports process label in metadata" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        Process.set_label({:special, :process})

        raise "an error"
      end)
    end)

    assert_eventually(
      [
        %{
          reason: %RuntimeError{message: "an error"},
          metadata: %{process_label: {:special, :process}}
        }
      ] = reported_events()
    )
  end

  test "emits telemetry events", %{test: test_name} do
    test_pid = self()

    :telemetry.attach_many(
      test_name,
      [
        [:tower, :report_event, :start],
        [:tower, :report_event, :stop],
        [:tower, :report_event, :exception]
      ],
      fn event, measures, metadata, config ->
        send(test_pid, {:telemetry_event, {event, measures, metadata, config}})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(test_name) end)

    capture_log(fn ->
      in_unlinked_process(fn ->
        raise "an error"
      end)
    end)

    assert_eventually([_] = reported_events())

    assert_receive {:telemetry_event, {[:tower, :report_event, :start], _, _, _}}
    assert_receive {:telemetry_event, {[:tower, :report_event, :stop], _, _, _}}
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
