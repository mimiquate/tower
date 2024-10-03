defmodule Tower.EphemeralReporter do
  @moduledoc """
  A very slim and naive built-in reporter, that just stores Tower events as process state.

  Possibly useful for development or testing.

  ## Example

      iex> Tower.EphemeralReporter.events()
      []
      iex> Application.put_env(:tower, :reporters, [Tower.EphemeralReporter])
      iex> Tower.attach()
      :ok
      iex> spawn(fn -> 1 / 0 end)
      iex> Process.sleep(200)
      :ok
      iex> [event] = Tower.EphemeralReporter.events()
      iex> event.kind
      :error
      iex> event.reason
      %ArithmeticError{message: "bad argument in arithmetic expression"}
      iex> Tower.detach()
      :ok
  """
  @behaviour Tower.Reporter

  @default_level :info

  use Agent

  require Logger

  alias Tower.Event

  @empty_events []

  def start_link(_opts) do
    Agent.start_link(fn -> @empty_events end, name: __MODULE__)
    |> case do
      {:error, {:already_started, existing_pid}} ->
        Logger.warning("""
        An attempt to start Tower.EphemeralReporter when it is already started was ignored.

        If you are manually starting Tower.EphemeralReporter, you can safely stop doing it given
        it is automatically started by Tower.
        """)

        {:ok, existing_pid}

      on_start ->
        on_start
    end
  end

  def stop(pid) do
    Agent.stop(pid)
  end

  @impl true
  def report_event(%Event{level: level} = event) do
    if Tower.equal_or_greater_level?(level, @default_level) do
      Agent.update(__MODULE__, fn events -> [event | events] end)
    end
  end

  @doc """
  Returns the list of all stored events.
  """
  @spec events() :: [Tower.Event.t()]
  def events do
    Agent.get(__MODULE__, & &1)
  end

  @spec reset() :: :ok
  def reset do
    Agent.update(__MODULE__, fn _events -> @empty_events end)
  end
end
