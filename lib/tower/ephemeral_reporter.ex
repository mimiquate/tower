defmodule Tower.EphemeralReporter do
  @max_events 50

  @moduledoc """
  A very slim and naive built-in reporter, that just stores Tower events as process state.

  It keeps only the last #{@max_events} events.

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
  @empty_events {:queue.new(), 0}

  use Agent

  require Logger

  alias Tower.Event

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
      Agent.update(
        __MODULE__,
        fn
          {q, count} when count >= @max_events ->
            {:queue.in(event, :queue.drop(q)), count}

          {q, count} ->
            {:queue.in(event, q), count + 1}
        end
      )
    end
  end

  @doc """
  Returns the list of all stored events.
  """
  @spec events() :: [Tower.Event.t()]
  def events do
    Agent.get(
      __MODULE__,
      fn {q, _} ->
        q
        |> :queue.reverse()
        |> :queue.to_list()
      end
    )
  end

  @spec reset() :: :ok
  def reset do
    Agent.update(__MODULE__, fn _events -> @empty_events end)
  end
end
