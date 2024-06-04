defmodule Tower.EphemeralReporter do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def report_exception(exception, stacktrace, _meta \\ %{})
      when is_exception(exception) and is_list(stacktrace) do
    Agent.update(
      __MODULE__,
      fn exceptions ->
        [
          %{timestamp: DateTime.utc_now(), exception: exception, stacktrace: stacktrace}
          | exceptions
        ]
      end
    )
  end

  def exceptions do
    Agent.get(__MODULE__, & &1)
  end
end
