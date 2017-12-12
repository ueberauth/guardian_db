defmodule Guardian.DB.Test.DataCase do
  use ExUnit.CaseTemplate
  alias Guardian.DB.Test.Repo
  alias Guardian.DB.Token
  import Guardian.DB.Test.Support.FileHelpers

  using _opts do
    quote do
      import Guardian.DB.Test.DataCase
      alias Guardian.DB.Test.Repo
    end
  end

  setup_all do
    on_exit(fn -> destroy_tmp_dir("priv/test/migrations") end)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  def get_token(token_id \\ "token-uuid"), do: Repo.get(Token.query_schema(), token_id)
end
