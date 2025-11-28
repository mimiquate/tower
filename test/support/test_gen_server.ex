defmodule TestGenServer do
  use GenServer

  @impl true
  def init(initial) do
    if function_exported?(Process, :set_label, 1) do
      Process.set_label({__MODULE__, init_args: initial})
    end

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
