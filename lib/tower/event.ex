defmodule Tower.Event do
  defstruct [:level, :kind, :exception, :message, :stacktrace, :metadata]

  @type metadata() :: %{log_event: :logger.log_event()}

  @type t :: %__MODULE__{
          level: :logger.level(),
          kind: atom(),
          exception: Exception.t(),
          message: binary(),
          stacktrace: list(),
          metadata: metadata()
        }
end
