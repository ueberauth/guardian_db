defmodule Mix.Tasks.Guardian.Db.Gen.MigrationTest do
  use ExUnit.Case, async: true
  import Mix.Tasks.Guardian.Db.Gen.Migration, only: [run: 1]
  import Guardian.DB.TestSupport.FileHelpers

  @tmp_path Path.join(tmp_path(), inspect(Guardian.Db.Gen.Migration))
  @migrations_path Path.join(@tmp_path, "migrations")

  defmodule My.Repo do
    def __adapter__ do
      true
    end

    def config do
      [priv: Path.join("priv/temp", inspect(Guardian.Db.Gen.Migration)), otp_app: :guardian_db]
    end
  end

  setup do
    create_dir(@migrations_path)
    on_exit(fn -> destroy_tmp_dir("priv/temp/Guardian.Db.Gen.Migration") end)
    :ok
  end

  test "generates a new migration" do
    run(["-r", to_string(My.Repo)])
    assert [name] = File.ls!(@migrations_path)
    assert String.match?(name, ~r/^\d{14}_guardiandb\.exs$/)
  end
end
