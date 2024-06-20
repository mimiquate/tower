defmodule TowerTest do
  use ExUnit.Case
  doctest Tower

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

    assert(
      [
        %{
          time: _,
          type: ArithmeticError,
          reason: "bad argument in arithmetic expression",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a raise" do
    in_unlinked_process(fn ->
      raise "error inside process"
    end)

    assert(
      [
        %{
          time: _,
          type: RuntimeError,
          reason: "error inside process",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a thrown string" do
    in_unlinked_process(fn ->
      throw("error")
    end)

    assert(
      [
        %{
          time: _,
          type: :nocatch,
          reason: "error",
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a thrown non-string" do
    in_unlinked_process(fn ->
      throw(something: "here")
    end)

    assert(
      [
        %{
          time: _,
          type: :nocatch,
          reason: [something: "here"],
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

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

    assert(
      [
        %{
          time: _,
          type: :exit,
          reason: :abnormal,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a kill exit" do
    in_unlinked_process(fn ->
      exit(:kill)
    end)

    assert(
      [
        %{
          time: _,
          type: :exit,
          reason: :kill,
          stacktrace: stacktrace
        }
      ] = reported_events()
    )

    assert is_list(stacktrace)
  end

  @tag capture_log: true
  test "reports a Logger.error" do
    in_unlinked_process(fn ->
      require Logger
      Logger.error("Something went wrong here")
    end)

    assert(
      [
        %{
          time: _,
          type: :error,
          reason: "Something went wrong here",
          stacktrace: []
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
end
