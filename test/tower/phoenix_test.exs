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
      adapter:
        case context[:adapter] do
          :bandit -> Bandit.PhoenixAdapter
          :cowboy -> Phoenix.Endpoint.Cowboy2Adapter
        end,
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

  @tag adapter: :bandit
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
          # Bandit doesn't provide the conn in the metadata
          plug_conn: nil
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  @tag adapter: :bandit
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
          kind: :throw,
          reason: "something",
          stacktrace: stacktrace,
          # Bandit doesn't provide the conn in the metadata
          plug_conn: nil
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert [_ | _] = stacktrace
  end

  @tag adapter: :bandit
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

  @tag adapter: :cowboy
  test "doesn't report exceptions that return 4xx status codes with Cowboy", %{base_url: base_url} do
    # Forcing Phoenix.ActionClauseError
    url = base_url <> "/show?param=invalid"

    capture_log(fn ->
      {:ok, {{_, 400, _}, _, _}} = :httpc.request(url)
    end)

    assert [] = Tower.EphemeralReporter.events()
  end

  @tag adapter: :bandit
  test "doesn't report exceptions that return 4xx status codes with Bandit", %{base_url: base_url} do
    # Forcing Phoenix.ActionClauseError
    url = base_url <> "/show?param=invalid"

    capture_log(fn ->
      {:ok, {{_, 400, _}, _, _}} = :httpc.request(url)
    end)

    assert [] = Tower.EphemeralReporter.events()
  end

  defp recent_datetime?(datetime) do
    diff =
      :logger.timestamp()
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.diff(datetime, :microsecond)

    diff >= 0 && diff < 100_000
  end
end
