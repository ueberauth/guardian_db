defmodule GuardianDb.Test.Repo.Migrations do
  use Ecto.Migration

  def up do
    create table(:guardian_tokens, primary_key: false) do
      add :jti, :string, primary_key: true
      add :aud, :string
      add :iss, :string
      add :sub, :string
      add :exp, :integer
      add :jwt, :text
      add :claims, :text

      timestamps
    end
  end

  def down do
    drop table(:guardian_tokens)
  end
end
