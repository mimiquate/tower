if Code.ensure_loaded?(Igniter) do
  defmodule Tower.Igniter do
    @prod_config_patterns [
      """
      if config_env() == :prod do
        __cursor__()
      end
      """,
      """
      if :prod == config_env() do
        __cursor__()
      end
      """
    ]

    def add_reporter_to_config(igniter, module) do
      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :tower,
        [:reporters],
        [module],
        updater: &Igniter.Code.List.append_new_to_list(&1, module)
      )
    end

    def runtime_configure_reporter(igniter, application, [{first_key, _} | _] = config) do
      if Igniter.Project.Config.configures_root_key?(igniter, "runtime.exs", application) do
        igniter
      else
        Igniter.create_or_update_elixir_file(
          igniter,
          "config/runtime.exs",
          default_runtime_exs_content(application, config),
          fn zipper ->
            zipper
            |> Igniter.Code.Common.move_to_cursor_match_in_scope(@prod_config_patterns)
            |> case do
              {:ok, zipper} ->
                if Igniter.Project.Config.configures_key?(zipper, application, first_key) do
                  {:ok, zipper}
                else
                  Igniter.Code.Function.move_to_function_call_in_current_scope(
                    zipper,
                    :=,
                    2,
                    fn call ->
                      Igniter.Code.Function.argument_equals?(call, 0, application)
                    end
                  )
                  |> case do
                    {:ok, zipper} ->
                      zipper

                    _ ->
                      Igniter.Code.Common.add_code(zipper, config_block(application, config))
                  end
                end

              :error ->
                Igniter.Code.Common.add_code(
                  zipper,
                  """
                  if config_env() == :prod do
                  #{config_block(application, config)}
                  end
                  """
                )
            end
          end
        )
      end
    end

    defp default_runtime_exs_content(application, config) do
      """
      import Config

      if config_env() == :prod do
      #{config_block(application, config)}
      end
      """
    end

    defp config_block(application, config) do
      """
      config #{inspect(application)},
        #{Enum.map_join(config, ",\n", fn {key, value} -> "#{key}: #{value}" end)}
      """
    end
  end
end
