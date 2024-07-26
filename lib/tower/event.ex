defmodule Tower.Event do
  defstruct [:time, :level, :kind, :reason, :stacktrace, :metadata]

  @type metadata() :: %{log_event: :logger.log_event()}

  @type t :: %__MODULE__{
          time: :logger.timestamp(),
          level: :logger.level(),
          kind: :error | :throw | :exit | :message,
          reason: Exception.t() | term(),
          stacktrace: Exception.stacktrace(),
          metadata: metadata()
        }
end
