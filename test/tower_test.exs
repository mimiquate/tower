defmodule TowerTest do
  use ExUnit.Case
  doctest Tower

  setup do
    Tower.attach()

    on_exit(fn ->
      Tower.detach()
    end)
  end

  test "starts with 0 exceptions" do
    Tower.EphemeralReporter.start_link([])

    assert [] = Tower.EphemeralReporter.errors()
  end

  test "reports a raise" do
    Tower.EphemeralReporter.start_link([])

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
      ] = Tower.EphemeralReporter.errors()
    )

    assert is_list(stacktrace)
  end

  test "reports a thrown string" do
    Tower.EphemeralReporter.start_link([])

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
      ] = Tower.EphemeralReporter.errors()
    )

    assert is_list(stacktrace)
  end

  test "reports a thrown non-string" do
    Tower.EphemeralReporter.start_link([])

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
      ] = Tower.EphemeralReporter.errors()
    )

    assert is_list(stacktrace)
  end

  test "reports arithmetic error" do
    Tower.EphemeralReporter.start_link([])

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
      ] = Tower.EphemeralReporter.errors()
    )

    assert is_list(stacktrace)
  end

  defp in_unlinked_process(fun) when is_function(fun, 0) do
    {:ok, pid} = Task.Supervisor.start_link()

    pid
    |> Task.Supervisor.async_nolink(fun)
    |> Task.yield()
  end
end
