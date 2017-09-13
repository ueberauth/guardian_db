defmodule GuardianDb.Test.DataCase do
  use ExUnit.CaseTemplate
  alias GuardianDb.Test.Repo

  using(_opts) do
    quote do
      import GuardianDb.Test.DataCase
      alias GuardianDb.Test.Repo
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end
end
