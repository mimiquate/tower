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
    put_env(:logger_metadata, [:user_id])

    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/runtime-error"

    start_link_supervised!({Plug.Cowboy, plug: Tower.TestPlug, scheme: :http, port: plug_port})

    capture_log(fn ->
      {:ok, {{_, 500, _}, _, _}} = :httpc.request(url)
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
          metadata: metadata,
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    # Plug.Cowboy doesn't report Logger.metadata when logging plug call
    # exceptions: https://github.com/elixir-plug/plug_cowboy/pull/103
    # assert metadata == %{user_id: 123}
    assert metadata == %{}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports erlang error during plug dispatch with Plug.Cowboy" do
    put_env(:logger_metadata, [:user_id])

    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/erlang-error"

    start_link_supervised!({Plug.Cowboy, plug: Tower.TestPlug, scheme: :http, port: plug_port})

    capture_log(fn ->
      {:ok, {{_, 500, _}, _, _}} = :httpc.request(url)
    end)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{},
          stacktrace: stacktrace,
          metadata: metadata,
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    # Plug.Cowboy doesn't report Logger.metadata when logging plug call
    # exceptions: https://github.com/elixir-plug/plug_cowboy/pull/103
    # assert metadata == %{user_id: 123}
    assert metadata == %{}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports uncaught throw during plug dispatch with Plug.Cowboy" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/uncaught-throw"

    start_link_supervised!({Plug.Cowboy, plug: Tower.TestPlug, scheme: :http, port: plug_port})

    capture_log(fn ->
      {:ok, {{_, 500, _}, _, _}} = :httpc.request(url)
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
          metadata: metadata,
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    # Plug.Cowboy doesn't report Logger.metadata when logging plug call
    # exceptions: https://github.com/elixir-plug/plug_cowboy/pull/103
    # assert metadata == %{user_id: 123}
    assert metadata == %{}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports abnormal exit during plug dispatch with Plug.Cowboy" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/abnormal-exit"

    start_link_supervised!({Plug.Cowboy, plug: Tower.TestPlug, scheme: :http, port: plug_port})

    capture_log(fn ->
      {:ok, {{_, 500, _}, _, _}} = :httpc.request(url)
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
          metadata: metadata,
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    # Plug.Cowboy doesn't provide stacktrace for exits
    assert [] = stacktrace
    # Plug.Cowboy doesn't report Logger.metadata when logging plug call
    # exceptions: https://github.com/elixir-plug/plug_cowboy/pull/103
    # assert metadata == %{user_id: 123}
    assert metadata == %{}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports runtime error during plug dispatch with Bandit" do
    put_env(:logger_metadata, [:user_id])

    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/runtime-error"

    capture_log(fn ->
      start_link_supervised!({Bandit, plug: Tower.TestPlug, scheme: :http, port: plug_port})

      {:ok, {{_, 500, _}, _, _}} = :httpc.request(url)
    end)

    assert(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %RuntimeError{message: "an error"},
          stacktrace: stacktrace,
          metadata: metadata,
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    assert metadata == %{user_id: 123}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports erlang error during plug dispatch with Bandit" do
    put_env(:logger_metadata, [:user_id])

    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/erlang-error"

    capture_log(fn ->
      start_link_supervised!({Bandit, plug: Tower.TestPlug, scheme: :http, port: plug_port})

      {:ok, {{_, 500, _}, _, _}} = :httpc.request(url)
    end)

    assert(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{},
          stacktrace: stacktrace,
          metadata: metadata,
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    assert metadata == %{user_id: 123}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports uncaught throw during plug dispatch with Bandit" do
    put_env(:logger_metadata, [:user_id])

    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/uncaught-throw"

    capture_log(fn ->
      start_link_supervised!({Bandit, plug: Tower.TestPlug, scheme: :http, port: plug_port})

      {:ok, {{_, 500, _}, _, _}} = :httpc.request(url)
    end)

    assert(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :throw,
          reason: "something",
          stacktrace: stacktrace,
          metadata: metadata,
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    assert metadata == %{user_id: 123}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports abnormal exit during plug dispatch with Bandit" do
    put_env(:logger_metadata, [:user_id])

    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/abnormal-exit"

    capture_log(fn ->
      start_link_supervised!({Bandit, plug: Tower.TestPlug, scheme: :http, port: plug_port})

      {:ok, {{_, 500, _}, _, _}} = :httpc.request(url)
    end)

    assert(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :exit,
          reason: :abnormal,
          stacktrace: stacktrace,
          metadata: metadata,
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    assert metadata == %{user_id: 123}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports message plug_conn manually" do
    Tower.report_message(
      :info,
      "Something interesting",
      plug_conn: Plug.Conn.assign(%Plug.Conn{}, :hello, "world")
    )

    assert(
      [
        %{
          level: :info,
          kind: :message,
          reason: "Something interesting",
          plug_conn: %Plug.Conn{assigns: %{hello: "world"}},
          by: nil
        }
      ] = Tower.EphemeralReporter.events()
    )
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
