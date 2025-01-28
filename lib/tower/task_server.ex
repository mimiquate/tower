defmodule Tower.TaskServer do
  use GenServer

  @name __MODULE__

  def start_link([]) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def run(fun) do
    :ok = GenServer.call(@name, {:run, fun})
  end

  # Callbacks

  @impl true
  def init(nil) do
    {:ok, %{tasks: %{}}}
  end

  @impl true
  def handle_call({:run, fun}, _from, state) do
    %{ref: ref} =
      Tower.TaskSupervisor
      |> Task.Supervisor.async_nolink(fun)

    {:reply, :ok, put_in(state.tasks[ref], fun)}
  end

  # The task completed successfully
  @impl true
  def handle_info({ref, result}, state) do
    # We don't care about the DOWN message after success, so let's demonitor and flush it
    Process.demonitor(ref, [:flush])

    {fun, state} = pop_in(state.tasks[ref])
    IO.puts("Got #{inspect(result)} for fun #{inspect(fun)}")
    {:noreply, state}
  end

  # The task failed
  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    {fun, state} = pop_in(state.tasks[ref])
    IO.puts("fun #{inspect(fun)} failed with reason #{inspect(reason)}")
    {:noreply, state}
  end
end
