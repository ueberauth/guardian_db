defmodule Mix.Tasks.Guardian.Db.Gen.MigrationTest do
  use ExUnit.Case, async: true
  import Mix.Tasks.Guardian.Db.Gen.Migration, only: [run: 1]
  import Guardian.DB.Test.Support.FileHelpers

  tmp_path = Path.join(tmp_path(), inspect(Guardian.Db.Gen.Migration))
  @migrations_path Path.join(tmp_path, "migrations")

  defmodule My.Repo do
    def __adapter__ do
      true
    end

    def config do
      [priv: "tmp/#{inspect(Guardian.Db.Gen.Migration)}", otp_app: :guardian_db]
    end
  end

  setup do
    create_dir(@migrations_path)
    on_exit(fn -> destroy_dir(tmp_path) end)
    :ok
  end

  test "generates a new migration" do
    IO.inspect(@migrations_path)
    run(["-r", to_string(My.Repo)])
    assert [name] = File.ls!(@migrations_path)
    assert String.match?(name, ~r/^\d{14}_guardiandb\.exs$/)
  end
end
