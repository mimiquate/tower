defmodule MyAppDomain do
  use Ash.Domain

  resources do
    resource(MyAppDomain.User)
  end
end

defmodule MyAppDomain.User do
  use Ash.Resource, domain: MyAppDomain

  actions do
    # Use the default implementation of the :read action
    defaults([:read])

    # and a create action, which we'll customize later
    create(:create)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string) do
      allow_nil? false
    end
  end
end
