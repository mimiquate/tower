defmodule TowerPlugTest do
  use ExUnit.Case

  use AssertEventually, timeout: 100, interval: 10

  setup do
    start_link_supervised!(Tower.EphemeralReporter)
    Tower.attach()

    on_exit(fn ->
      Tower.detach()
    end)
  end

  @tag capture_log: true
  test "reports arithmetic error when a Plug.Conn IS present" do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/arithmetic-error"

    start_link_supervised!({Plug.Cowboy, plug: Tower.TestPlug, scheme: :http, port: plug_port})

    {:ok, _response} = :httpc.request(url)

    assert_eventually(
      [
        %{
          id: id,
          datetime: datetime,
          level: :error,
          kind: :error,
          reason: %ArithmeticError{message: "bad argument in arithmetic expression"},
          stacktrace: stacktrace,
          plug_conn: %Plug.Conn{} = plug_conn
        }
      ] = Tower.EphemeralReporter.events()
    )

    assert String.length(id) == 36
    assert recent_datetime?(datetime)
    assert is_list(stacktrace)
    assert Plug.Conn.request_url(plug_conn) == url
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
