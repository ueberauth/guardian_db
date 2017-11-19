defmodule GuardianDb.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [app: :guardian_db,
     version: @version,
     description: "DB tracking for token validity",
     elixir: "~> 1.4 or ~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [guardian_db: :test],
     aliases: aliases(),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:guardian, "~> 1.0"},
     {:ecto, "~> 2.2"},
     {:postgrex, "~> 0.13", optional: true},
     {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
     {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false}]
  end

  defp package do
    [
      maintainers: ["Daniel Neighman", "Sean Callan", "Sonny Scroggin"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/hassox/guardian_db"},
      files: ~w(lib) ++ ~w(CHANGELOG.md LICENSE mix.exs README.md)
    ]
  end

  defp aliases do
    ["test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
