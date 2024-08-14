defmodule TestApp.UncaughtThrowWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    throw("something")

    :ok
  end
end

defmodule TestApp.AbnormalExitWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    exit(:abnormal)

    :ok
  end
end

defmodule TestApp.ArithmeticErrorWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    raise "error from an Oban worker"

    :ok
  end
end

defmodule TestApp.Repo.Migrations.AddOban do
  use Ecto.Migration

  def change do
    Oban.Migrations.up()
  end
end

defmodule TestApp.Repo do
  use Ecto.Repo, otp_app: :test_app, adapter: Ecto.Adapters.SQLite3
end
