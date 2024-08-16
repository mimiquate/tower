defmodule Tower.MixProject do
  use Mix.Project

  @description "Solid error handling and reporting"
  @source_url "https://github.com/mimiquate/tower"
  @version "0.4.0"

  def project do
    [
      app: :tower,
      description: @description,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),

      # Docs
      name: "Tower",
      source_url: @source_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets],
      mod: {Tower.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uniq, "~> 0.6.0"},
      {:telemetry, "~> 1.1"},

      # Dev
      {:ex_doc, "~> 0.34.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},

      # Test
      {:assert_eventually, "~> 1.0", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:bandit, "~> 1.5", only: :test},
      {:oban, "~> 2.18", only: :test},
      {:ecto_sqlite3, "~> 0.17.0", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: ["README.md"]
    ]
  end
end
