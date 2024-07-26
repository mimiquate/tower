defmodule Tower.Event do
  defstruct [:level, :kind, :reason, :stacktrace, :metadata]

  @type metadata() :: %{log_event: :logger.log_event()}

  @type t :: %__MODULE__{
          level: :logger.level(),
          kind: :error | :throw | :exit | :message,
          reason: Exception.t() | binary(),
          stacktrace: Exception.stacktrace(),
          metadata: metadata()
        }
end
