defmodule TowerIgniterTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  describe "configure_reporter/2" do
    test "from scratch" do
      test_project()
      |> Tower.Igniter.configure_reporter(
        Reporter,
        :reporter,
        api_key: ~s[System.get_env("API_KEY")]
      )
      |> assert_creates(
        "config/config.exs",
        """
        import Config
        config :tower, reporters: [Reporter]
        """
      )
      |> assert_creates(
        "config/runtime.exs",
        """
        import Config

        if config_env() == :prod do
          config :reporter,
            api_key: System.get_env("API_KEY")
        end
        """
      )
    end

    test "modifies existing tower configs if available" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [ReporterOne]
          """,
          "config/runtime.exs" => """
          import Config
          """
        }
      )
      |> Tower.Igniter.configure_reporter(
        ReporterTwo,
        :reporter_two,
        api_key: ~s[System.get_env("API_KEY")]
      )
      |> assert_has_patch(
        "config/config.exs",
        """
        |import Config
        |
        - |config :tower, reporters: [ReporterOne]
        + |config :tower, reporters: [ReporterOne, ReporterTwo]
        """
      )
      |> assert_has_patch(
        "config/runtime.exs",
        """
        |import Config
        |
        + |if config_env() == :prod do
        + |  config :reporter_two, api_key: System.get_env("API_KEY")
        + |end
        + |
        """
      )
    end

    test "modifies existing tower configs if config_env() == :prod block exists" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [ReporterOne]
          """,
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            IO.puts("hello")
          end
          """
        }
      )
      |> Tower.Igniter.configure_reporter(
        ReporterTwo,
        :reporter_two,
        api_key: ~s[System.get_env("API_KEY")]
      )
      |> assert_has_patch(
        "config/config.exs",
        """
        |import Config
        |
        - |config :tower, reporters: [ReporterOne]
        + |config :tower, reporters: [ReporterOne, ReporterTwo]
        """
      )
      |> assert_has_patch(
        "config/runtime.exs",
        """
        |if config_env() == :prod do
        |  IO.puts("hello")
        + |config :reporter_two, api_key: System.get_env("API_KEY")
        |end
        |
        """
      )
    end

    test "does not modify existing tower_rollbar configs if config_env() == :prod block exists" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [ReporterOne, ReporterTwo]
          """,
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            config :reporter_two, api_key: System.get_env("API_KEY")
          end
          """
        }
      )
      |> Tower.Igniter.configure_reporter(
        ReporterTwo,
        :reporter_two,
        api_key: ~s[System.get_env("API_KEY")]
      )
      |> assert_unchanged()
    end

    test "is idempotent" do
      test_project()
      |> Tower.Igniter.configure_reporter(
        Reporter,
        :reporter,
        api_key: ~s[System.get_env("API_KEY")]
      )
      |> apply_igniter!()
      |> Tower.Igniter.configure_reporter(
        Reporter,
        :reporter,
        api_key: ~s[System.get_env("API_KEY")]
      )
      |> assert_unchanged()
    end
  end
end
