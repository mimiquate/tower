defmodule TowerPhoenixTest do
  use ExUnit.Case

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup context do
    on_exit(fn ->
      Tower.EphemeralReporter.reset()
    end)

    # An ephemeral port hopefully not being in the host running this code
    port = 51111
    host = "127.0.0.1"

    Application.put_env(
      :phoenix_app,
      Tower.PhoenixApp.Endpoint,
      Keyword.merge(
        [
          server: true,
          http: [port: port],
          url: [scheme: "http", port: port, host: host],
          render_errors: [formats: [html: Tower.PhoenixApp.ErrorHTML], layout: false]
        ],
        context[:endpoint_options]
      )
    )

    capture_log(fn ->
      start_link_supervised!(Tower.PhoenixApp.Endpoint)
    end)

    %{base_url: "http://#{host}:#{port}"}
  end

  @tag endpoint_options: [adapter: Bandit.PhoenixAdapter]
  test "reports runtime error during Phoenix.Endpoint dispatch with Bandit", %{base_url: base_url} do
    put_env(:logger_metadata, [:user_id])

    url = base_url <> "/runtime-error"

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
    assert metadata == %{user_id: 123}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  @tag endpoint_options: [adapter: Bandit.PhoenixAdapter]
  test "reports erlang error during Phoenix.Endpoint dispatch with Bandit", %{base_url: base_url} do
    put_env(:logger_metadata, [:user_id])

    url = base_url <> "/erlang-error"

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
    assert metadata == %{user_id: 123}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  @tag endpoint_options: [adapter: Bandit.PhoenixAdapter]
  test "reports uncaught throw during Phoenix.Endpoint dispatch with Bandit", %{
    base_url: base_url
  } do
    put_env(:logger_metadata, [:user_id])

    url = base_url <> "/uncaught-throw"

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
    assert metadata == %{user_id: 123}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  @tag endpoint_options: [adapter: Bandit.PhoenixAdapter]
  test "reports abnormal exit during Phoenix.Endpoint dispatch with Bandit", %{base_url: base_url} do
    put_env(:logger_metadata, [:user_id])

    url = base_url <> "/abnormal-exit"

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
    assert [_ | _] = stacktrace
    assert metadata == %{user_id: 123}
    assert Plug.Conn.request_url(plug_conn) == url
  end

  @tag endpoint_options: [adapter: Phoenix.Endpoint.Cowboy2Adapter, drainer: false]
  test "doesn't report exceptions that return 4xx status codes with Cowboy", %{base_url: base_url} do
    # Forcing Phoenix.ActionClauseError
    url = base_url <> "/show?param=invalid"

    capture_log(fn ->
      {:ok, {{_, 400, _}, _, _}} = :httpc.request(url)
    end)

    assert [] = Tower.EphemeralReporter.events()
  end

  @tag endpoint_options: [adapter: Bandit.PhoenixAdapter]
  test "doesn't report exceptions that return 4xx status codes with Bandit", %{base_url: base_url} do
    # Forcing Phoenix.ActionClauseError
    url = base_url <> "/show?param=invalid"

    capture_log(fn ->
      {:ok, {{_, 400, _}, _, _}} = :httpc.request(url)
    end)

    assert [] = Tower.EphemeralReporter.events()
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
