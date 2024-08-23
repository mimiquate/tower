defmodule Tower.Reporter do
  @moduledoc """
  Behaviour that can be implemented to write Tower reporters.

  Tower comes built-in with a very naive `Tower.EphemeralReporter`, that implements
  this behavior, which can be useful for development and testing purposes.

  Separate packages that implement this behaviour:

    * [tower_email](https://hex.pm/packages/tower_email) ([`TowerEmail.Reporter`](https://hexdocs.pm/tower_email/TowerEmail.Reporter.html))
    * [tower_rollbar](https://hex.pm/packages/tower_rollbar) ([`TowerRollbar.Reporter`](https://hexdocs.pm/tower_rollbar/TowerRollbar.Reporter.html))
    * [tower_slack](https://hex.pm/packages/tower_slack) ([`TowerSlack.Reporter`](https://hexdocs.pm/tower_slack/TowerSlack.Reporter.html))
  """

  @doc """
  Function that will be called with every event handled by Tower.
  """
  @callback report_event(event :: Tower.Event.t()) :: :ok
end
