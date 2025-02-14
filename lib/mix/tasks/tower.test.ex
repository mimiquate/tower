defmodule Mix.Tasks.Tower.Test do
  @shortdoc "Generates a runtime exception to test Tower is well configured"

  use Mix.Task

  @requirements ["app.start"]

  @impl true
  def run(_args) do
    Tower.test()

    # Allow some time for any reporters reporting in async processes to finish.
    Process.sleep(3_000)
  end
end
