defmodule Tower do
  @moduledoc """
  Tower is an Elixir package that tries to do one job well, **handle** error **events** in an
  Elixir application **and inform** about them to configured **reporters** (one or many).
  """

  alias Tower.Event

  @default_reporters [Tower.EphemeralReporter]

  @doc """
  Attaches the necessary handlers to capture events.

  Attaches a [:logger](https://www.erlang.org/doc/apps/kernel/logger) [handler](https://www.erlang.org/doc/apps/kernel/logger_handler), which captures all uncaught events.

  Additionally attaches other handlers specifically tailored for some packages that
  do catch errors and have their own specific error handling and emit events instead
  of letting errors get to the logger handler, like oban or bandit.
  """
  @spec attach() :: :ok
  def attach do
    :ok = Tower.LoggerHandler.attach()
    :ok = Tower.BanditExceptionHandler.attach()
    :ok = Tower.ObanExceptionHandler.attach()
  end

  @doc "Detaches the handlers."
  @spec detach() :: :ok
  def detach do
    :ok = Tower.LoggerHandler.detach()
    :ok = Tower.BanditExceptionHandler.detach()
    :ok = Tower.ObanExceptionHandler.detach()
  end

  @doc """
  Asks Tower to handle a manually caught error.

  ## Example

  ```elixir
  try do
    # possibly crashing code
  catch
    kind, reason ->
      Tower.handle_caught(kind, reason, __STACKTRACE__)
  end
  ```
  """
  @spec handle_caught(Exception.kind(), Event.reason(), Exception.stacktrace()) :: :ok
  @spec handle_caught(Exception.kind(), Event.reason(), Exception.stacktrace(), Keyword.t()) ::
          :ok
  def handle_caught(kind, reason, stacktrace, options \\ []) do
    Event.from_caught(kind, reason, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to handle a manually caught exception.

  ## Example

  ```elixir
  try do
    # possibly crashing code
  rescue
    exception ->
      Tower.handle_exception(exception, __STACKTRACE__)
  end
  ```
  """
  @spec handle_exception(Exception.t(), Exception.stacktrace()) :: :ok
  @spec handle_exception(Exception.t(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_exception(exception, stacktrace, options \\ [])
      when is_exception(exception) and is_list(stacktrace) do
    Event.from_exception(exception, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to handle a manually caught throw.

  ## Example

  ```elixir
  try do
    # possibly throwing code
  catch
    thrown_value ->
      Tower.handle_throw(thrown_value, __STACKTRACE__)
  end
  ```
  """
  @spec handle_throw(term(), Exception.stacktrace()) :: :ok
  @spec handle_throw(term(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_throw(reason, stacktrace, options \\ []) do
    Event.from_throw(reason, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to handle a manually caught exit.

  ## Example

  ```elixir
  try do
    # possibly exiting code
  catch
    :exit, exit_reason ->
      Tower.handle_exit(exit_reason, __STACKTRACE__)
  end
  ```
  """
  @spec handle_exit(term(), Exception.stacktrace()) :: :ok
  @spec handle_exit(term(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_exit(reason, stacktrace, options \\ []) do
    Event.from_exit(reason, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to handle a message of certain level.

  ## Examples

  ```elixir
  Tower.handle_message(:emergency, "System is falling apart")
  ```
  ```elixir
  Tower.handle_message(:error, "Unknown error has ocurred", metadata: %{any_key: "here"})
  ```
  ```elixir
  Tower.handle_message(:info, "Just something interesting", metadata: %{interesting: "additional data"})
  ```
  """
  @spec handle_message(:logger.level(), term()) :: :ok
  @spec handle_message(:logger.level(), term(), Keyword.t()) :: :ok
  def handle_message(level, message, options \\ []) do
    Event.from_message(level, message, options)
    |> report_event()
  end

  @doc false
  def equal_or_greater_level?(%Event{level: level1}, level2) when is_atom(level2) do
    equal_or_greater_level?(level1, level2)
  end

  @doc false
  def equal_or_greater_level?(level1, level2) when is_atom(level1) and is_atom(level2) do
    :logger.compare_levels(level1, level2) in [:gt, :eq]
  end

  defp report_event(%Event{} = event) do
    reporters()
    |> Enum.each(fn reporter ->
      async(fn ->
        reporter.report_event(event)
      end)
    end)
  end

  defp reporters do
    Application.get_env(:tower, :reporters, @default_reporters)
  end

  defp async(fun) do
    Tower.TaskSupervisor
    |> Task.Supervisor.start_child(fun)
  end
end
