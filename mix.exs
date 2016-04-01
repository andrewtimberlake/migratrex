defmodule Migratrex.Mixfile do
  use Mix.Project

  def project do
    [app: :migratrex,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     name: "Migratrex",
     source_url: "https://github.com/andrewtimberlake/migratrex",
     description: "Build Ecto models and tests from existing database (Postgresql)",
     package: package]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto, "~> 2.0-beta"}
    ]
  end

  defp package do
    [maintainers: ["Andrew Timberlake"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/andrewtimberlake/migratrex"}]
  end
end
