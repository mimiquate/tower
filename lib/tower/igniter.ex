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
              patterns = env_config_patterns(env)

              zipper
              |> Igniter.Code.Common.move_to_cursor_match_in_scope(patterns)
              |> case do
                {:ok, zipper} ->
                  {:ok, zipper}

                :error ->
                  zipper
                  |> Igniter.Code.Common.add_code("""
                  if config_env() == #{inspect(env)} do
                  end
                  """)
                  |> Igniter.Code.Common.move_to_cursor_match_in_scope(patterns)
              end
            else
              {:ok, zipper}
            end
            |> case do
              {:ok, zipper} ->
                items
                |> Enum.map(fn {key, value} ->
                  {
                    key,
                    case value do
                      {:code, code} ->
                        code

                      other ->
                        other
                        |> Macro.escape()
                        |> Sourceror.to_string()
                        |> Sourceror.parse_string!()
                    end
                  }
                end)
                |> Enum.reduce_while(
                  {:ok, zipper},
                  fn {key, value}, {:ok, zipper} ->
                    Igniter.Project.Config.modify_config_code(
                      zipper,
                      [key],
                      application,
                      value,
                      updater: &{:ok, &1}
                    )
                    |> case do
                      {:ok, _} = ok_result -> {:cont, ok_result}
                      other_result -> {:halt, other_result}
                    end
                  end
                )

              :error ->
                {:error, "Could not modify #{@runtime_file_path}"}
            end
          end
        end
      )
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
