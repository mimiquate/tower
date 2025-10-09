defmodule TestGenServer do
  use GenServer

  @impl true
  def init(initial) do
    {:ok, initial}
  end
end
