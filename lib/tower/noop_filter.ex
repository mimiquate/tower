defmodule Tower.NoopFilter do
  @moduledoc """
  A no-op `Tower.Filter` implementation that reports every event.

  This is the default filter used by Tower when no custom filter is configured.
  """

  @behaviour Tower.Filter

  @impl true
  def should_report?(_reporter, _event), do: true
end
