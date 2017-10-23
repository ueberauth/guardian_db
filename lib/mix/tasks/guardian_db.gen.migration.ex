defmodule Mix.Tasks.GuardianDb.Gen.Migration do
  @shortdoc "Generates GuardianDb's migration"

  @moduledoc """
  Generates the required GuardianDb's database migration
  """
  use Mix.Task

  alias Mix.Generator

  @doc false
  def run(_args) do
    if Mix.Project.umbrella?() do
      Mix.raise "mix guardian_db.gen.migration can only be run inside an application directory"
    end

    Generator.create_directory("./priv/repo/migrations")

    source_path = Path.join(Application.app_dir(:guardian_db), "priv/templates/migration.exs")

    generated_file = EEx.eval_file(source_path, [module_prefix: app_module()])
    target_file = Path.join("priv/repo/migrations", "#{timestamp()}_guardiandb.exs")
    Generator.create_file(target_file, generated_file)

  end

  defp app_module do
    Mix.Project.config |> Keyword.fetch!(:app) |> to_string() |> Macro.camelize()
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

end
