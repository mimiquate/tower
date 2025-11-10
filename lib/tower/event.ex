defmodule Tower.Event do
  @moduledoc """
  A struct representing a captured event.

  Tower converts every captured error and message into a struct of this type
  before passing along to reporters.
  """

  defstruct [
    :id,
    :similarity_id,
    :datetime,
    :level,
    :kind,
    :reason,
    :stacktrace,
    :log_event,
    :plug_conn,
    :metadata,
    :by
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
          id: UUIDv7.t(),
          similarity_id: non_neg_integer(),
          datetime: DateTime.t(),
          level: level(),
          kind: error_kind() | non_error_kind(),
          reason: reason(),
          stacktrace: Exception.stacktrace() | nil,
          log_event: :logger.log_event() | nil,
          plug_conn: struct() | nil,
          metadata: map(),
          by: atom() | nil
        }

  @similarity_source_attributes [:level, :kind, :reason, :stacktrace]
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
    %{
      level: :error,
      kind: :error,
      reason: exception,
      stacktrace: stacktrace
    }
    |> from_map(options)
  end

  @doc false
  @spec from_exit(term(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_exit(reason, stacktrace, options \\ []) do
    %{
      level: :error,
      kind: :exit,
      reason: reason,
      stacktrace: stacktrace
    }
    |> from_map(options)
  end

  @doc false
  @spec from_throw(term(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_throw(reason, stacktrace, options \\ []) do
    %{
      level: :error,
      kind: :throw,
      reason: reason,
      stacktrace: stacktrace
    }
    |> from_map(options)
  end

  @doc false
  @spec from_message(level(), term(), Keyword.t()) :: t()
  def from_message(level, message, options \\ []) do
    %{
      level: level,
      kind: :message,
      reason: message
    }
    |> from_map(options)
  end

  defp from_map(map, options) when is_map(map) do
    struct!(
      __MODULE__,
      %{id: UUIDv7.generate()}
      |> Map.merge(map)
      |> Map.merge(attributes_from_options(options))
    )
    |> put_similarity_id()
  end

  defp attributes_from_options(options) do
    log_event = Keyword.get(options, :log_event)

    pid = log_event_pid(log_event) || self()

    %{
      datetime: event_datetime(log_event),
      log_event: log_event,
      plug_conn: plug_conn(options),
      metadata:
        %{pid: pid}
        |> Map.merge(maybe_process_label(pid))
        |> Map.merge(log_event[:meta] || %{})
        |> Map.merge(Enum.into(Logger.metadata(), %{}))
        |> Map.take(allowed_metadata_keys())
        |> Map.merge(Keyword.get(options, :metadata, %{})),
      by: Keyword.get(options, :by)
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

  defp plug_conn(options) do
    Keyword.get(options, :plug_conn, Keyword.get(options, :log_event)[:meta][:conn])
  end

  defp log_event_pid(%{meta: %{pid: pid}}), do: pid
  defp log_event_pid(_log_event), do: nil

  if function_exported?(:proc_lib, :get_label, 1) do
    defp maybe_process_label(pid) when is_pid(pid) do
      case :proc_lib.get_label(pid) do
        :undefined -> %{}
        process_label -> %{process_label: process_label}
      end
    end

    defp maybe_process_label(_other), do: %{}
  else
    defp maybe_process_label(_pid), do: %{}
  end

  defp allowed_metadata_keys do
    # Backwards compatible
    Application.get_env(
      :tower,
      :logger_metadata,
      Application.fetch_env!(:tower, :allowed_metadata)
    )
  end

  defp put_similarity_id(%__MODULE__{} = event) do
    struct!(event, similarity_id: :erlang.phash2(Map.take(event, @similarity_source_attributes)))
  end
end
