defmodule AuroraUix.MixProject do
  use Mix.Project

  def project do
    [
      app: :aurora_uix,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_add_apps: [:eex]
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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.22.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      consistency: [
        "format",
        "compile --warnings-as-error",
        "credo --strict",
        "dialyzer",
        "doctor"
      ]
    ]
  end
end
