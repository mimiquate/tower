defmodule TestGenServer do
  use GenServer

  @impl true
  def init(initial) do
    {:ok, initial}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :error_in_call, state}
  end
end
