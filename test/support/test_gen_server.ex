defmodule TestGenServer do
  use GenServer

  @impl true
  def init(initial) do
    {:ok, initial}
  end

  @impl true
  def handle_call({:stop, reason}, _from, state) do
    {:stop, reason, state}
  end
end
