defmodule GuardianDb.TestSerializer do
  @behaviour Guardian.Serializer
  def for_token(sub), do: {:ok, sub}
  def from_token(sub), do: {:ok, sub}
end

alias GuardianDb.Test.Repo

defmodule GuardianDb.TestCase do
  use ExUnit.CaseTemplate

  ExUnit.configure(exclude: :config_test)

  using(_opts) do
    quote do
      import Ecto.Query
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  end
end

ExUnit.start()

{:ok, _pid} = Repo.start_link

Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
