if Code.ensure_loaded?(Igniter) do
  defmodule Tower.Igniter do
    def add_reporter_to_config(igniter, reporter) do
      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :tower,
        [:reporters],
        [reporter],
        updater: &Igniter.Code.List.append_new_to_list(&1, reporter)
      )
    end
  end
end
