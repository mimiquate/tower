defmodule Tower.Event do
  defstruct [:level, :kind, :exception, :message, :stacktrace, :metadata]

  @type metadata() :: %{log_event: :logger.log_event()}

  @type t :: %__MODULE__{
          level: :logger.level(),
          kind: :exception | :throw | :exit | :message,
          exception: Exception.t(),
          message: binary(),
          stacktrace: Exception.stacktrace(),
          metadata: metadata()
        }
end
