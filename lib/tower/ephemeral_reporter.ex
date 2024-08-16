defmodule Tower.EphemeralReporter do
  @behaviour Tower.Reporter

  @default_level :info

  use Agent

  alias Tower.Event

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @impl true
  def report_event(%Event{level: level} = event) do
    if Tower.equal_or_greater_level?(level, @default_level) do
      Agent.update(__MODULE__, fn events -> [event | events] end)
    end
  end

  def events do
    Agent.get(__MODULE__, & &1)
  end
end
