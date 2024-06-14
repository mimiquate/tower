defmodule Tower.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link(
      [
        {Task.Supervisor, name: Tower.TaskSupervisor}
      ],
      strategy: :one_for_one,
      name: Tower.Supervisor
    )
  end
end
