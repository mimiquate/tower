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
        api_key: {:code, Sourceror.parse_string!(~s[System.get_env("REPORTER_API_KEY")])},
        other_key: {:code, Sourceror.parse_string!(~s[System.get_env("REPORTER_OTHER_KEY")])}
      )
      |> assert_creates(
        "config/runtime.exs",
        """
        import Config

        config :reporter,
          api_key: System.get_env("REPORTER_API_KEY"),
          other_key: System.get_env("REPORTER_OTHER_KEY")
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
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "123")
      |> assert_has_patch(
        "config/runtime.exs",
        """
        |import Config
        + |config :reporter, api_key: "123"
        """
      )
    end

    test "does not append same config again" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          config :reporter, api_key: "123"
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "123")
      |> assert_unchanged()
    end

    test "does not modify existing key value yet appends new key" do
      test_project(
        files: %{
          "config/runtime.exs" => """
          import Config

          config :reporter, api_key: "123"
          """
        }
      )
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "456", other_key: "789")
      |> assert_has_patch(
        "config/runtime.exs",
        """
        - |config :reporter, api_key: "123"
        + |config :reporter, api_key: "123", other_key: "789"
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

    test "is idempotent" do
      test_project()
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "123")
      |> apply_igniter!()
      |> Tower.Igniter.runtime_configure_reporter(:reporter, api_key: "123")
      |> assert_unchanged()
    end
  end
end
