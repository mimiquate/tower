defmodule TowerPlugTest do
  use ExUnit.Case

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    on_exit(fn ->
      Tower.EphemeralReporter.reset()
    end)
  end

  test "reports runtime error during plug dispatch with Plug.Cowboy" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/runtime-error"

    start_link_supervised!({Plug.Cowboy, plug: Tower.TestPlug, scheme: :http, port: plug_port})

    capture_log(fn ->
      {:ok, _response} = :httpc.request(url)
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
          plug_conn: %Plug.Conn{} = plug_conn
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports uncaught throw during plug dispatch with Plug.Cowboy" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/uncaught-throw"

    start_link_supervised!({Plug.Cowboy, plug: Tower.TestPlug, scheme: :http, port: plug_port})

    capture_log(fn ->
      {:ok, _response} = :httpc.request(url)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :throw,
          reason: "something",
          stacktrace: stacktrace,
          plug_conn: %Plug.Conn{} = plug_conn
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports abnormal exit during plug dispatch with Plug.Cowboy" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/abnormal-exit"

    start_link_supervised!({Plug.Cowboy, plug: Tower.TestPlug, scheme: :http, port: plug_port})

    capture_log(fn ->
      {:ok, _response} = :httpc.request(url)
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
          plug_conn: %Plug.Conn{} = plug_conn
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    # Plug.Cowboy doesn't provide stacktrace for exits
    assert [] = stacktrace
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports runtime error during plug dispatch with Bandit" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/runtime-error"

    capture_log(fn ->
      start_link_supervised!({Bandit, plug: Tower.TestPlug, scheme: :http, port: plug_port})

      {:ok, _response} = :httpc.request(url)
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
          plug_conn: %Plug.Conn{} = plug_conn
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports uncaught throw during plug dispatch with Bandit" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/uncaught-throw"

    capture_log(fn ->
      start_link_supervised!({Bandit, plug: Tower.TestPlug, scheme: :http, port: plug_port})

      {:error, :socket_closed_remotely} = :httpc.request(url)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          # Bandit doesn't handle uncaught throws inside plug call so it becomes a gen server exit.
          # We have no control over this kind.
          kind: :exit,
          reason: {:bad_return_value, "something"},
          stacktrace: stacktrace,
          # Bandit doesn't handle uncaught throws so it doesn't provide the conn in the metadata
          plug_conn: nil
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    # Bandit doesn't provide the stacktrace for throws
    # assert [_ | _] = stacktrace
    assert [] = stacktrace
  end

  test "reports abnormal exit during plug dispatch with Bandit" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/abnormal-exit"

    capture_log(fn ->
      start_link_supervised!({Bandit, plug: Tower.TestPlug, scheme: :http, port: plug_port})

      {:error, :socket_closed_remotely} = :httpc.request(url)
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
          # Bandit doesn't handle exits so it doesn't provide the conn in the metadata
          plug_conn: nil
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  test "reports message plug_conn manually" do
    Tower.handle_message(
      :info,
      "Something interesting",
      plug_conn: Plug.Conn.assign(%Plug.Conn{}, :hello, "world")
    )

    assert_eventually(
      [
        %{
          level: :info,
          kind: :message,
          reason: "Something interesting",
          plug_conn: %Plug.Conn{assigns: %{hello: "world"}}
        }
      ] = Tower.EphemeralReporter.events()
    )
  end

  defp recent_datetime?(datetime) do
    diff =
      :logger.timestamp()
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.diff(datetime, :microsecond)

    diff >= 0 && diff < 100_000
  end
end
