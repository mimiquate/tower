defmodule TowerGenServerTest do
  use ExUnit.Case

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    on_exit(fn ->
      Tower.EphemeralReporter.reset()
    end)
  end

  test "reports if GenServer callback raises" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [], name: :example_gen_server)
        GenServer.cast(pid, {:raise, "something"})
      end)
    end)

    assert_eventually(
      [
        %{
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "something"},
          stacktrace: [{TestGenServer, :handle_cast, 2, _} | _],
          metadata: %{
            process:
              %{
                group_leader: _group_leader,
                pid: _pid,
                process_label: TestGenServer,
                registered_name: :example_gen_server
              } = process_metadata
          },
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )

    if Version.match?(System.version(), ">= 1.19.0") do
      assert %{
               gen_server: %{
                 name: :example_gen_server,
                 last_message: {:"$gen_cast", {:raise, "something"}}
               }
             } = process_metadata
    end
  end

  # throws inside gen_server are interpreted as return values
  # https://github.com/erlang/otp/pull/6053
  test "reports bad return exit if GenServer callback throws" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [])
        GenServer.cast(pid, {:throw, "something"})
      end)
    end)

    assert_eventually(
      [
        %{
          level: :error,
          kind: :exit,
          reason: {:bad_return_value, "something"},
          stacktrace: [],
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )
  end

  test "doesn't report if GenServer callback exits normally" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [])
        GenServer.cast(pid, {:exit, :normal})
      end)
    end)

    assert [] = reported_events()
  end

  test "doesn't report if GenServer callback stops normally" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [])
        GenServer.cast(pid, {:stop, :normal})
      end)
    end)

    assert [] = reported_events()
  end

  test "doesn't report if GenServer stops normally" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [])
        GenServer.stop(pid)
      end)
    end)

    assert [] = reported_events()
  end

  test "reports if GenServer callback exits abnormally" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [])
        GenServer.cast(pid, {:exit, :abnormal})
      end)
    end)

    assert_eventually(
      [
        %{
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: [{TestGenServer, :handle_cast, 2, _} | _],
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )
  end

  test "reports if GenServer callback stops abnormally" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [])
        GenServer.cast(pid, {:stop, :abnormal})
      end)
    end)

    assert_eventually(
      [
        %{
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: [],
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )
  end

  test "reports if GenServer stops abnormally" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [])
        GenServer.stop(pid, :abnormal)
      end)
    end)

    assert_eventually(
      [
        %{
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: [],
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )
  end

  test "reports two events when both GenServer terminates abnormally and client exits" do
    capture_log(fn ->
      in_unlinked_process(fn ->
        {:ok, pid} = GenServer.start(TestGenServer, [])
        # Client also raises because it doesn't receive a response from call
        GenServer.call(pid, {:stop, :abnormal})
      end)
    end)

    assert_eventually(
      [
        # client exit
        %{
          level: :error,
          kind: :exit,
          reason: {:abnormal, {GenServer, :call, _args}},
          stacktrace: [_ | _],
          by: Tower.LoggerHandler
        },
        # server exit
        %{
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: [],
          by: Tower.LoggerHandler
        }
      ] = reported_events()
    )
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
end
