defmodule Mix.Tasks.Tower.Test do
  @shortdoc "Generates a runtime exception to test Tower is well configured"

  use Mix.Task

  @requirements ["app.start"]

  @impl true
  def run(_args) do
    # Avoid automatic BEAM halt after task finishes so we allow time for any
    # reporters reporting in async processes to finish.
    System.no_halt(true)
    Tower.test()
  end
end
