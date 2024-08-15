defmodule Tower.MixProject do
  use Mix.Project

  @description "Solid error handling and reporting"
  @source_url "https://github.com/mimiquate/tower"
  @version "0.3.0"

  def project do
    [
      app: :tower,
      description: @description,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      dialyzer: [
        plt_local_path: "priv/plts"
      ],

      # Docs
      name: "Tower",
      source_url: @source_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Tower.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uniq, "~> 0.6.1"},

      # Dev
      {:ex_doc, "~> 0.34.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},

      # Test
      {:assert_eventually, "~> 1.0", only: :test}
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
