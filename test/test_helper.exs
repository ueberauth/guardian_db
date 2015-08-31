defmodule GuardianDb.TestSerializer do
  @behaviour Guardian.Serializer
  def for_token(aud), do: { :ok, aud }
  def from_token(aud), do: { :ok, aud }
end

alias GuardianDb.Test.Repo

defmodule GuardianDb.TestCase do
  use ExUnit.CaseTemplate

  using(opts) do
    quote do
      import Ecto.Query
    end
  end

  setup do
    Ecto.Adapters.SQL.begin_test_transaction(Repo)

    ExUnit.Callbacks.on_exit(fn ->
      Ecto.Adapters.SQL.rollback_test_transaction(Repo)
    end)
  end
end

ExUnit.start()

_   = Ecto.Storage.down(Repo)
:ok = Ecto.Storage.up(Repo)

{:ok, _pid} = Repo.start_link

Code.require_file "support/migrations.exs", __DIR__

:ok = Ecto.Migrator.up(Repo, 0, GuardianDb.Test.Repo.Migrations, log: false)
Process.flag(:trap_exit, true)
