if Code.ensure_loaded?(Igniter) do
  defmodule Tower.Igniter do
    def reporters_list_append(igniter, module) do
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        :tower,
        [:reporters],
        [module],
        updater: &Igniter.Code.List.append_new_to_list(&1, module)
      )
    end

    def runtime_configure_reporter(igniter, application, items) do
      items
      |> Enum.reduce(igniter, fn {key, value}, igniter ->
        Igniter.Project.Config.configure(
          igniter,
          "runtime.exs",
          application,
          [key],
          value,
          updater: &{:ok, &1}
        )
      end)
    end
  end
end
