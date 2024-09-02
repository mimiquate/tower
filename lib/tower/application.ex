defmodule Tower.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    with {:ok, pid} <-
           Supervisor.start_link(
             [
               Tower.EphemeralReporter,
               {Task.Supervisor, name: Tower.TaskSupervisor}
             ],
             strategy: :one_for_one,
             name: Tower.Supervisor
           ),
         :ok <- Tower.attach() do
      {:ok, pid}
    end
  end

  @impl true
  def stop(_state) do
    Tower.detach()
  end
end
