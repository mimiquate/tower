defmodule TowerIgniterTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  describe "reporters_list_append/2" do
    test "from scratch" do
      test_project()
      |> Tower.Igniter.reporters_list_append(Reporter)
      |> assert_creates(
        "config/config.exs",
        """
        import Config
        config :tower, reporters: [Reporter]
        """
      )
    end

    test "appends to list if existing config" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [ReporterOne]
          """
        }
      )
      |> Tower.Igniter.reporters_list_append(ReporterTwo)
      |> assert_has_patch(
        "config/config.exs",
        """
        |import Config
        |
        - |config :tower, reporters: [ReporterOne]
        + |config :tower, reporters: [ReporterOne, ReporterTwo]
        """
      )
    end

    test "does nothing if module already listed" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [ReporterOne, ReporterTwo]
          """
        }
      )
      |> Tower.Igniter.reporters_list_append(ReporterTwo)
      |> assert_unchanged()
    end

    test "is idempotent" do
      test_project()
      |> Tower.Igniter.reporters_list_append(Reporter)
      |> apply_igniter!()
      |> Tower.Igniter.reporters_list_append(Reporter)
      |> assert_unchanged()
    end
  end

  describe "runtime_configure_reporter/4" do
    test "from scratch with string values" do
      test_project()
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "123", other: "abc")
      |> assert_creates(
        "config/runtime.exs",
        """
        import Config
        config :reporter, api_key: "123", other: "abc"
        """
      )
    end

    test "from scratch with code value" do
      test_project()
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: {:code, Sourceror.parse_string!(~s[System.get_env("REPORTER_API_KEY")])}
      )
      |> assert_creates(
        "config/runtime.exs",
        """
        import Config
        config :reporter, api_key: System.get_env("REPORTER_API_KEY")
        """
      )
    end

    test "from scratch with env" do
      test_project()
      |> Tower.Igniter.runtime_configure_reporter(:reporter, [api_key: "123"], env: :prod)
      |> assert_creates(
        "config/runtime.exs",
        """
        import Config

        if config_env() == :prod do
          config :reporter, api_key: "123"
        end
        """
      )
    end

    test "appends to existing runtime config" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(:reporter, [api_key: "123"], env: :prod)
      |> assert_has_patch(
        "config/runtime.exs",
        """
        |import Config
        |
        + |if config_env() == :prod do
        + |  config :reporter, api_key: "123"
        + |end
        + |
        """
      )
    end

    test "writes inside existing prod block if present" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            IO.puts("hello")
          end
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(:reporter, [api_key: "123"], env: :prod)
      |> assert_has_patch(
        "config/runtime.exs",
        """
        |if config_env() == :prod do
        |  IO.puts("hello")
        + |config :reporter, api_key: "123"
        |end
        |
        """
      )
    end

    test "does not append same config again in existing env block" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            config :reporter, api_key: "123"
          end
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(:reporter, [api_key: "123"], env: :prod)
      |> assert_unchanged()
    end

    test "does not modify existing key value yet appends new key in env block" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            config :reporter, api_key: "123"
          end
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        [api_key: "456", other_key: "789"],
        env: :prod
      )
      |> assert_has_patch(
        "config/runtime.exs",
        """
        |if config_env() == :prod do
        - |  config :reporter, api_key: "123"
        + |  config :reporter, api_key: "123", other_key: "789"
        |end
        """
      )
    end

    test "does not modify existing configs despite different" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          config :reporter, api_key: "123"
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "456")
      |> assert_unchanged()
    end

    test "does not modify existing config in top level if configured for env" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          config :reporter, api_key: "123"
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(:reporter, [api_key: "123"], env: :prod)
      |> assert_unchanged()
    end

    test "is idempotent" do
      test_project()
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "123")
      |> apply_igniter!()
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "123")
      |> assert_unchanged()
    end
  end
end
