defmodule TowerTest do
  use ExUnit.Case
  doctest Tower

  use AssertEventually, timeout: 100, interval: 10

  setup do
    Tower.attach()
    start_reporter()

    on_exit(fn ->
      Tower.detach()
    end)
  end

  test "starts with 0 exceptions" do
    assert [] = reported_events()
  end

  @tag capture_log: true
  test "reports arithmetic error" do
    in_unlinked_process(fn ->
      1 / 0
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :error,
          kind: ArithmeticError,
          reason: "bad argument in arithmetic expression",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a raise" do
    in_unlinked_process(fn ->
      raise "error inside process"
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :error,
          kind: RuntimeError,
          reason: "error inside process",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a thrown string" do
    in_unlinked_process(fn ->
      throw("error")
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :error,
          kind: :throw,
          reason: "error",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a thrown non-string" do
    in_unlinked_process(fn ->
      throw(something: "here")
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :error,
          kind: :throw,
          reason: [something: "here"],
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
    assert is_list(stacktrace)
  end

  test "doesn't report an normal exit" do
    in_unlinked_process(fn ->
      exit(:normal)
    end)

    assert [] = reported_events()
  end

  @tag capture_log: true
  test "reports an abnormal exit" do
    in_unlinked_process(fn ->
      exit(:abnormal)
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a kill exit" do
    in_unlinked_process(fn ->
      exit(:kill)
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :error,
          kind: :exit,
          reason: :kill,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "doesn't report a Logger.error by default" do
    in_unlinked_process(fn ->
      require Logger
      Logger.error("Something went wrong here")
    end)

    assert [] = reported_events()
  end

  @tag capture_log: true
  test "reports a Logger.error (if enabled)" do
    put_env(:log_level, :error)

    in_unlinked_process(fn ->
      require Logger
      Logger.error("Something went wrong here")
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :error,
          kind: nil,
          reason: "Something went wrong here",
          stacktrace: []
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
  end

  @tag capture_log: true
  test "reports a Logger.error (if enabled) with charlist" do
    put_env(:log_level, :error)

    in_unlinked_process(fn ->
      require Logger

      Logger.error([
        "Postgrex.Protocol",
        32,
        40,
        "#PID<0.2612.0>",
        ") disconnected: " | "** (DBConnection.ConnectionError) tcp recv (idle): closed"
      ])
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :error,
          kind: nil,
          reason:
            "Postgrex.Protocol (#PID<0.2612.0>) disconnected: ** (DBConnection.ConnectionError) tcp recv (idle): closed",
          stacktrace: []
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
  end

  @tag capture_log: true
  test "reports a Logger structured report" do
    in_unlinked_process(fn ->
      require Logger
      Logger.critical(something: :reported, this: :critical)
    end)

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :critical,
          kind: nil,
          reason: [something: :reported, this: :critical],
          stacktrace: []
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
  end

  test "reports message manually" do
    Tower.handle_message(:info, "Something interesting")

    assert_eventually(
      [
        %{
          id: id,
          time: time,
          level: :info,
          kind: nil,
          reason: "Something interesting",
          stacktrace: []
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
  end

  test "reports Exception manually" do
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
          time: time,
          level: :error,
          kind: ArithmeticError,
          reason: "bad argument in arithmetic expression",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "manually reports a thrown string" do
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
          time: time,
          level: :error,
          kind: :throw,
          reason: "error",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "manually reports an abnormal exit" do
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
          time: time,
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert String.length(id) == 36
    assert_in_delta(time, :logger.timestamp(), 100_000)
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
end
