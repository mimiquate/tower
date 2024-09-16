defmodule Tower.Reporter do
  @moduledoc """
  Behaviour that can be implemented to write Tower reporters.

  Tower comes built-in with a very naive `Tower.EphemeralReporter`, that implements
  this behavior, which can be useful for development and testing purposes.

  Separate packages that implement this behaviour:

    * [tower_email](https://hex.pm/packages/tower_email) ([`TowerEmail`](https://hexdocs.pm/tower_email))
    * [tower_rollbar](https://hex.pm/packages/tower_rollbar) ([`TowerRollbar`](https://hexdocs.pm/tower_rollbar))
    * [tower_sentry](https://hex.pm/packages/tower_sentry) ([`TowerSentry`](https://hexdocs.pm/tower_sentry))
    * [tower_slack](https://hex.pm/packages/tower_slack) ([`TowerSlack`](https://hexdocs.pm/tower_slack))
  """

  @doc """
  Function that will be called with every event handled by Tower.
  """
  @callback report_event(event :: Tower.Event.t()) :: :ok
end
