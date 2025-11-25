defmodule TestGenServer do
  use GenServer

  @impl true
  def init(initial) do
    Process.set_label(__MODULE__)
    {:ok, initial}
  end

  @impl true
  def handle_call({:stop, reason}, _from, state) do
    {:stop, reason, state}
  end

  @impl true
  def handle_cast({:raise, reason}, state) do
    raise(reason)
    {:noreply, state}
  end

  def handle_cast({:exit, reason}, state) do
    exit(reason)
    {:noreply, state}
  end

  def handle_cast({:stop, reason}, state) do
    {:stop, reason, state}
  end

  def handle_cast({:throw, reason}, state) do
    throw(reason)
    {:noreply, state}
  end
end
