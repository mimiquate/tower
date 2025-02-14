defmodule Mix.Tasks.Tower.Test do
  @shortdoc "Generates a runtime exception to test Tower is well configured"

  use Mix.Task

  @requirements ["app.start"]

  @impl true
  def run(_args) do
    Tower.test()

    # Avoid automatic BEAM halt after task finishes so we allow time for any
    # reporters reporting in async processes to finish.
    Mix.shell().info(
      "A test exception was generated. You should see it now wherever your configured reporter(s) should report to."
    )

    Mix.shell().prompt("press ENTER to exit:")
  end
end
