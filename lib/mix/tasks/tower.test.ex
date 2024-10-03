defmodule Mix.Tasks.Tower.Test do
  @shortdoc "Generates a runtime exception to test Tower is well configured"

  use Mix.Task

  @requirements ["app.start"]

  @impl true
  def run(_args) do
    Tower.test()
  end
end
