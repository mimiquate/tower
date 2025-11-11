defmodule TestApp.UncaughtThrowWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.metadata(user_id: 123, secret: "secret")

    throw("something")

    :ok
  end
end

defmodule TestApp.AbnormalExitWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.metadata(user_id: 123, secret: "secret")

    exit(:abnormal)

    :ok
  end
end

defmodule TestApp.RuntimeErrorWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.metadata(user_id: 123, secret: "secret")

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

defmodule TestApp.Domain do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(TestApp.Domain.User)
  end
end

defmodule TestApp.Domain.User do
  use Ash.Resource, domain: TestApp.Domain

  actions do
    create(:create)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:name, :string) do
      allow_nil?(false)
    end
  end
end
