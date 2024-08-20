defmodule Tower.Config do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def update(options) do
    Agent.update(__MODULE__, fn current -> Keyword.merge(current, options) end)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end
end
