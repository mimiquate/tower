defmodule Tower.Event do
  @moduledoc """
  A struct representing a captured event.

  Tower converts every captured error and message into a struct of this type
  before passing along to reporters.
  """

  defstruct [
    :id,
    :datetime,
    :level,
    :kind,
    :reason,
    :stacktrace,
    :log_event,
    :plug_conn,
    :metadata
  ]

  @type error_kind :: :error | :exit | :throw
  @type non_error_kind :: :message
  @type reason :: Exception.t() | term()
  @type level :: :logger.level()

  @typedoc """
  A struct representing a captured event.

  Tower converts every captured error and message into a struct of this type
  before passing along to reporters.
  """
  @type t :: %__MODULE__{
          id: Uniq.UUID.t(),
          datetime: DateTime.t(),
          level: level(),
          kind: error_kind() | non_error_kind(),
          reason: reason(),
          stacktrace: Exception.stacktrace() | nil,
          log_event: :logger.log_event() | nil,
          plug_conn: struct() | nil,
          metadata: map()
        }

  @logger_time_unit :microsecond

  @doc false
  @spec from_caught(Exception.kind(), reason(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_caught(kind, reason, stacktrace, options \\ [])

  def from_caught(:error, exception, stacktrace, options) when is_exception(exception) do
    from_exception(exception, stacktrace, options)
  end

  def from_caught(:error, reason, stacktrace, options) do
    Exception.normalize(:error, reason, stacktrace)
    |> from_exception(stacktrace, options)
  end

  def from_caught(:exit, reason, stacktrace, options) do
    from_exit(reason, stacktrace, options)
  end

  def from_caught(:throw, reason, stacktrace, options) do
    from_throw(reason, stacktrace, options)
  end

  @doc false
  @spec from_exception(Exception.t(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_exception(exception, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      id: new_id(),
      datetime: event_datetime(log_event),
      level: :error,
      kind: :error,
      reason: exception,
      stacktrace: stacktrace,
      log_event: log_event,
      plug_conn: plug_conn(options),
      metadata: Keyword.get(options, :metadata, %{})
    }
  end

  @doc false
  @spec from_exit(term(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_exit(reason, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      id: new_id(),
      datetime: event_datetime(log_event),
      level: :error,
      kind: :exit,
      reason: reason,
      stacktrace: stacktrace,
      log_event: log_event,
      plug_conn: plug_conn(options),
      metadata: Keyword.get(options, :metadata, %{})
    }
  end

  @doc false
  @spec from_throw(term(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_throw(reason, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      id: new_id(),
      datetime: event_datetime(log_event),
      level: :error,
      kind: :throw,
      reason: reason,
      stacktrace: stacktrace,
      log_event: log_event,
      plug_conn: plug_conn(options),
      metadata: Keyword.get(options, :metadata, %{})
    }
  end

  @doc false
  @spec from_message(level(), term(), Keyword.t()) :: t()
  def from_message(level, message, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      id: new_id(),
      datetime: event_datetime(log_event),
      level: level,
      kind: :message,
      reason: message,
      log_event: log_event,
      plug_conn: plug_conn(options),
      metadata: Keyword.get(options, :metadata, %{})
    }
  end

  defp event_datetime(log_event) do
    log_event
    |> event_timestamp()
    |> DateTime.from_unix!(@logger_time_unit)
  end

  defp event_timestamp(%{meta: %{time: log_event_time}}) do
    log_event_time
  end

  defp event_timestamp(_) do
    :logger.timestamp()
  end

  defp new_id do
    Uniq.UUID.uuid7()
  end

  defp plug_conn(options) do
    Keyword.get(options, :plug_conn, Keyword.get(options, :log_event)[:meta][:conn])
  end
end
