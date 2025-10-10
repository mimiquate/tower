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

  @impl true
  def handle_cast({:throw, reason}, state) do
    throw(reason)
    {:noreply, state}
  end

  def handle_cast({:raise, reason}, state) do
    raise(reason)
    {:noreply, state}
  end
end
