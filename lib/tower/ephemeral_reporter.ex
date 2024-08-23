defmodule Tower.EphemeralReporter do
  @moduledoc """
  A very slim and naive built-in reporter, that just stores Tower events as process state.

  Possibly useful for development or testing.

  ## Example

      iex> {:ok, pid} = Tower.EphemeralReporter.start_link([])
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
      iex> Tower.EphemeralReporter.stop(pid)
      :ok
  """
  @behaviour Tower.Reporter

  @default_level :info

  use Agent

  alias Tower.Event

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
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
end
