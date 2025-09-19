if Code.ensure_loaded?(Igniter) do
  defmodule Tower.Igniter do
    @runtime_file_path "config/runtime.exs"
    @default_runtime_file_content """
    import Config
    """

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

    def runtime_configure_reporter(igniter, application, items, opts \\ []) do
      env = opts[:env]

      igniter
      |> Igniter.include_or_create_file(@runtime_file_path, @default_runtime_file_content)
      |> Igniter.update_elixir_file(
        @runtime_file_path,
        fn zipper ->
          if Igniter.Project.Config.configures_root_key?(zipper, application) do
            {:ok, zipper}
          else
            if env do
              zipper
              |> Igniter.Code.Common.move_to_cursor_match_in_scope(env_config_patterns(env))
            else
              {:ok, zipper}
            end
            |> case do
              {:ok, zipper} ->
                if Igniter.Project.Config.configures_root_key?(zipper, application) do
                  {:ok, zipper}
                else
                  Igniter.Code.Common.add_code(zipper, config_block(application, items))
                end

              :error ->
                Igniter.Code.Common.add_code(zipper, env_config_block(env, application, items))
            end
          end
        end
      )
    end

    defp env_config_block(env, application, config) do
      """
      if config_env() == #{inspect(env)} do
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

    defp env_config_patterns(env) do
      [
        """
        if config_env() == #{inspect(env)} do
          __cursor__()
        end
        """,
        """
        if #{inspect(env)} == config_env() do
          __cursor__()
        end
        """
      ]
    end
  end
end
