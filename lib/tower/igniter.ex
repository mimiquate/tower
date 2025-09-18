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

    def add_reporter_to_config(igniter, reporter_module) do
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        :tower,
        [:reporters],
        [reporter_module],
        updater: &Igniter.Code.List.append_new_to_list(&1, reporter_module)
      )
    end

    def add_reporter_config(igniter, reporter_app_name, [{first_key, _} | _] = config) do
      if Igniter.Project.Config.configures_root_key?(igniter, "runtime.exs", reporter_app_name) do
        igniter
      else
        Igniter.create_or_update_elixir_file(
          igniter,
          "config/runtime.exs",
          default_runtime_exs_content(reporter_app_name, config),
          fn zipper ->
            zipper
            |> Igniter.Code.Common.move_to_cursor_match_in_scope(@prod_config_patterns)
            |> case do
              {:ok, zipper} ->
                if Igniter.Project.Config.configures_key?(zipper, reporter_app_name, first_key) do
                  {:ok, zipper}
                else
                  Igniter.Code.Function.move_to_function_call_in_current_scope(
                    zipper,
                    :=,
                    2,
                    fn call ->
                      Igniter.Code.Function.argument_equals?(call, 0, reporter_app_name)
                    end
                  )
                  |> case do
                    {:ok, _zipper} ->
                      config
                      |> Enum.reduce(
                        zipper,
                        fn {key, value}, zipper ->
                          zipper
                          |> Igniter.Project.Config.modify_config_code(
                            [key],
                            reporter_app_name,
                            Sourceror.parse_string!(value)
                          )
                        end
                      )
                      |> then(&{:ok, &1})

                    _ ->
                      Igniter.Code.Common.add_code(
                        zipper,
                        config_block(reporter_app_name, config)
                      )
                  end
                end

              :error ->
                Igniter.Code.Common.add_code(
                  zipper,
                  """
                  if config_env() == :prod do
                  #{config_block(reporter_app_name, config)}
                  end
                  """
                )
            end
          end
        )
      end
    end

    defp default_runtime_exs_content(name, config) do
      """
      import Config

      if config_env() == :prod do
      #{config_block(name, config)}
      end
      """
    end

    defp config_block(name, config) do
      """
      config #{inspect(name)},
        #{Enum.map_join(config, ",\n", fn {key, value} -> "#{key}: #{value}" end)}
      """
    end
  end
end
