defmodule TowerMultipleTest do
  use ExUnit.Case

  # use AssertEventually, timeout: 100, interval: 10

  # import ExUnit.CaptureLog, only: [capture_log: 1]

  test "multiple towers" do
    {:ok, ephemeral_reporter_1} =
      Tower.EphemeralReporter.start_link(name: Tower1.EphemeralReporter)

    {:ok, ephemeral_reporter_2} =
      Tower.EphemeralReporter.start_link(name: Tower2.EphemeralReporter)

    assert [] = Tower.EphemeralReporter.events(ephemeral_reporter_1)
    assert [] = Tower.EphemeralReporter.events(ephemeral_reporter_2)

    spawn(fn -> 1 / 0 end)
    Process.sleep(200)

    assert [] = Tower.EphemeralReporter.events(ephemeral_reporter_1)
    assert [] = Tower.EphemeralReporter.events(ephemeral_reporter_2)

    {:ok, tower_1} =
      Tower.start_link(name: Tower1, reporters: [{Tower.EphemeralReporter, ephemeral_reporter_1}])

    {:ok, tower_2} =
      Tower.start_link(name: Tower2, reporters: [{Tower.EphemeralReporter, ephemeral_reporter_2}])

    spawn(fn -> 1 / 0 end)
    Process.sleep(200)

    assert [_event] = Tower.EphemeralReporter.events(ephemeral_reporter_1)
    assert [_event] = Tower.EphemeralReporter.events(ephemeral_reporter_2)

    :ok = Tower.stop(Tower1)

    spawn(fn -> 1 / 0 end)
    Process.sleep(200)

    assert [_event] = Tower.EphemeralReporter.events(ephemeral_reporter_1)
    assert [_event1, _event2] = Tower.EphemeralReporter.events(ephemeral_reporter_2)
    # :ok = Tower.EphemeralReporter.stop(ephemeral_reporter_1)
  end
end
