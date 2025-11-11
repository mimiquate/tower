defmodule MyAppDomain do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(MyAppDomain.User)
  end
end

defmodule MyAppDomain.User do
  use Ash.Resource, domain: MyAppDomain

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
