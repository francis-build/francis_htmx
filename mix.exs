defmodule FrancisHtmx.MixProject do
  use Mix.Project
  @version "0.2.0"
  def project do
    [
      name: "Francis HTMX",
      app: :francis_htmx,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/filipecabaco/francis_htmx",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Francis module for HTMX integration",
      dialyzer: [
        # Put the project-level PLT in the priv/ directory (instead of the default _build/ location)
        plt_file: {:no_warn, "priv/plts/project.plt"},
        plt_add_apps: [:mix, :iex]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:francis, "~> 0.1"},
      {:phoenix_html, "~> 3.3"},
      {:req, "~> 0.4.5", only: :test},
      {:floki, "~> 0.35.2", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "test", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Filipe Cabaço"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/filipecabaco/francis_htmx"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      formatters: ["html", "epub"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
end
