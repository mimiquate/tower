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

    assert Tower.EphemeralReporter.exceptions() |> length() == 0
  end

  test "reports a raise" do
    Tower.EphemeralReporter.start_link([])

    {:ok, pid} = Task.Supervisor.start_link()

    task =
      Task.Supervisor.async_nolink(
        pid,
        fn -> raise "from process" end
      )

    Task.yield(task)

    assert Tower.EphemeralReporter.exceptions() |> length() == 1
  end
end
