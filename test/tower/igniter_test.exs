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

  describe "runtime_configure_reporter/2" do
    test "from scratch" do
      test_project()
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: ~s[System.get_env("REPORTER_API_KEY")]
      )
      |> assert_creates(
        "config/runtime.exs",
        """
        import Config

        if config_env() == :prod do
          config :reporter,
            api_key: System.get_env("REPORTER_API_KEY")
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
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: ~s[System.get_env("REPORTER_API_KEY")]
      )
      |> assert_has_patch(
        "config/runtime.exs",
        """
        |import Config
        |
        + |if config_env() == :prod do
        + |  config :reporter, api_key: System.get_env("REPORTER_API_KEY")
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
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: ~s[System.get_env("REPORTER_API_KEY")]
      )
      |> assert_has_patch(
        "config/runtime.exs",
        """
        |if config_env() == :prod do
        |  IO.puts("hello")
        + |config :reporter, api_key: System.get_env("REPORTER_API_KEY")
        |end
        |
        """
      )
    end

    test "does not modify existing configs if config_env() == :prod block exists" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            config :reporter, api_key: System.get_env("REPORTER_API_KEY")
          end
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: ~s[System.get_env("REPORTER_API_KEY")]
      )
      |> assert_unchanged()
    end

    test "does not modify existing configs despite different" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            config :reporter, stale_key: System.get_env("REPORETER_STALE_KEY")
          end
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: ~s[System.get_env("REPORTER_API_KEY")]
      )
      |> assert_unchanged()
    end

    test "does not modify existing configs exists" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          config :reporter, api_key: System.get_env("REPORTER_API_KEY")
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: ~s[System.get_env("REPORTER_API_KEY")]
      )
      |> assert_unchanged()
    end

    test "is idempotent" do
      test_project()
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: ~s[System.get_env("REPORTER_API_KEY")]
      )
      |> apply_igniter!()
      |> Tower.Igniter.runtime_configure_reporter(
        :reporter,
        api_key: ~s[System.get_env("REPORTER_API_KEY")]
      )
      |> assert_unchanged()
    end
  end
end
