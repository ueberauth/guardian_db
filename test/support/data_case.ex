defmodule Guardian.DB.Test.DataCase do
  use ExUnit.CaseTemplate
  alias Guardian.DB.Test.Repo
  alias Guardian.DB.Token

  using _opts do
    quote do
      import Guardian.DB.Test.DataCase
      alias Guardian.DB.Test.Repo
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  def get_token(token_id \\ "token-uuid"),
    do: Repo.get(Token.query_schema(), token_id)
end
