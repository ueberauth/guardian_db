defmodule GuardianDb.Mixfile do
  use Mix.Project

  @version "0.8.0"

  def project do
    [app: :guardian_db,
     version: @version,
     description: "DB tracking for token validity",
     elixir: "~> 1.2",
     elixirc_paths: _elixirc_paths(Mix.env),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [guardian_db: :test],
     aliases: aliases(),
     deps: deps()]
  end

  def application do
    [applications: _applications(Mix.env)]
  end

  defp _applications(:test), do: [:postgrex, :ecto, :logger]
  defp _applications(_), do: [:logger]

  defp _elixirc_paths(:test), do: ["lib", "test/support"]
  defp _elixirc_paths(_), do: ["lib"]

  defp deps do
    [{:guardian, "~> 0.14"},
     {:ecto, "~> 2.1"},
     {:postgrex, ">= 0.11.1", optional: true},
     {:ex_doc, "~> 0.8", only: :dev},
     {:earmark, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [
      maintainers: ["Daniel Neighman"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/hassox/guardian_db"},
      files: ~w(lib) ++ ~w(CHANGELOG.md LICENSE mix.exs README.md)
    ]
  end

  defp aliases do
    ["test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
