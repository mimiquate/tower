defmodule Tower.MixProject do
  use Mix.Project

  @description "Flexible exception tracking and reporting in Elixir"
  @source_url "https://github.com/mimiquate/tower"
  @changelog_url @source_url <> "/blob/-/CHANGELOG.md"
  @version "0.8.4"

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
      dialyzer: [
        plt_add_apps: [:mix],
        plt_core_path: "plts/core",
        plt_local_path: "plts/local"
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
      extra_applications: [:logger, :inets],
      env: [
        reporters: [Tower.EphemeralReporter],
        log_level: :critical,
        ignored_exceptions: [],
        logger_metadata: []
      ],
      mod: {Tower.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry, "~> 1.1"},
      {:uuid_v7, "~> 0.6.0"},

      # Optional
      {:bandit, "~> 1.6", optional: true},
      {:igniter, "~> 0.6", optional: true},

      # Dev
      {:ex_doc, "~> 0.38.1", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},

      # Test
      {:assert_eventually, "~> 1.0", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:phoenix, "~> 1.7", only: :test},
      {:phoenix_html, "~> 4.1", only: :test},
      {:oban, "~> 2.19", only: :test},
      {:ecto_sqlite3, "~> 0.21.0", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @changelog_url
      }
    ]
  end

  defp docs do
    [
      main: "Tower",
      extras: [
        "CHANGELOG.md": [title: "Changelog"]
      ],
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@11.0.2/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({
          startOnLoad: false,
          theme: document.body.className.includes("dark") ? "dark" : "default"
        });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""
end
