defmodule Mix.Tasks.Guardian.Db.Gen.Migration do
  @shortdoc "Generates Guardian.DB's migration"

  @moduledoc """
  Generates the required GuardianDb's database migration.

  It allows custom schema name, using the config
  entry `schema_name`.
  """
  use Mix.Task

  import Mix.Ecto
  import Mix.Generator

  @doc false
  def run(args) do
    no_umbrella!("ecto.gen.migration")

    repos = parse_repo(args)

    Enum.each(repos, fn repo ->
      ensure_repo(repo, args)
      path = Ecto.Migrator.migrations_path(repo)

      source_path =
        :guardian_db
        |> Application.app_dir()
        |> Path.join("priv/templates/migration.exs.eex")

      config = Application.fetch_env!(:guardian, Guardian.DB)

      schema_name =
        config
        |> Keyword.get(:schema_name, "guardian_tokens")
        |> String.to_atom()

      prefix = Keyword.get(config, :prefix, nil)

      generated_file =
        EEx.eval_file(source_path,
          module_prefix: app_module(),
          schema_name: schema_name,
          db_prefix: prefix
        )

      target_file = Path.join(path, "#{timestamp()}_guardiandb.exs")
      create_directory(path)
      create_file(target_file, generated_file)
    end)
  end

  defp app_module do
    Mix.Project.config()
    |> Keyword.fetch!(:app)
    |> to_string()
    |> Macro.camelize()
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
