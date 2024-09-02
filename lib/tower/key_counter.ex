defmodule Tower.KeyCounter do
  use Agent

  @empty_state %{}

  def start_link(_initial_value) do
    Agent.start_link(fn -> @empty_state end, name: __MODULE__)
  end

  def get_count(key) do
    Agent.get(__MODULE__, fn state -> Map.get(state, key) end)
  end

  def increment(key) do
    Agent.update(
      __MODULE__,
      fn state ->
        {_, new_state} =
          Map.get_and_update(state, key, fn current_value ->
            {current_value, (current_value || 0) + 1}
          end)

        new_state
      end
    )
  end
end
