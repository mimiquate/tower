defmodule TowerPhoenixTest do
  use ExUnit.Case

  use AssertEventually, timeout: 100, interval: 10

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    on_exit(fn ->
      Tower.EphemeralReporter.reset()
    end)

    # An ephemeral port hopefully not being in the host running this code
    port = 51111
    host = "127.0.0.1"

    Application.put_env(
      :phoenix_app,
      Tower.PhoenixApp.Endpoint,
      adapter: Bandit.PhoenixAdapter,
      server: true,
      http: [port: port],
      url: [scheme: "http", port: port, host: host],
      render_errors: [formats: [html: Tower.PhoenixApp.ErrorHTML], layout: false]
    )

    capture_log(fn ->
      start_link_supervised!(Tower.PhoenixApp.Endpoint)
    end)

    %{base_url: "http://#{host}:#{port}"}
  end

  test "reports runtime error during Phoenix.Endpoint dispatch with Bandit", %{base_url: base_url} do
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
          plug_conn: %Plug.Conn{} = plug_conn
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
    assert Plug.Conn.request_url(plug_conn) == url
  end

  test "reports uncaught throw during Phoenix.Endpoint dispatch with Bandit", %{
    base_url: base_url
  } do
    capture_log(fn ->
      {:ok, {{_, 500, _}, _, _}} = :httpc.request(base_url <> "/uncaught-throw")
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

  test "reports abnormal exit during Phoenix.Endpoint dispatch with Bandit", %{base_url: base_url} do
    capture_log(fn ->
      {:ok, {{_, 500, _}, _, _}} = :httpc.request(base_url <> "/abnormal-exit")
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

  defp recent_datetime?(datetime) do
    diff =
      :logger.timestamp()
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.diff(datetime, :microsecond)

    diff >= 0 && diff < 100_000
  end
end
