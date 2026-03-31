defmodule TowerPhoenixLiveViewTest do
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
          render_errors: [formats: [html: Tower.PhoenixApp.ErrorHTML], layout: false],
          live_view: [signing_salt: "12345678"],
          secret_key_base: "zdPrVL6rBX9DNzGu4iOgN+jsJbEjP+uWrTfAmCZZx0xQ+Ro3yxaiGOsmPgohslou"
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
  test "reports runtime error during Phoenix Live View render with Bandit", %{base_url: base_url} do
    put_env(:logger_metadata, [:user_id])

    url = base_url <> "/live/runtime-error"

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
          stacktrace: [_ | _],
          metadata: %{process: %{pid: _pid}, user_id: 123},
          plug_conn: %Plug.Conn{} = plug_conn,
          by: Tower.LoggerHandler
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert Plug.Conn.request_url(plug_conn) == url
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
