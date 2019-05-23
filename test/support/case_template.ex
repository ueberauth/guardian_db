defmodule Guardian.DB.TestSupport.CaseTemplate do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias Guardian.DB.TestSupport.Repo
  alias Guardian.DB.Token
  import Guardian.DB.TestSupport.FileHelpers

  using _opts do
    quote do
      import Guardian.DB.TestSupport.CaseTemplate
      alias Guardian.DB.TestSupport.Repo
    end
  end

  setup_all do
    on_exit(fn -> destroy_tmp_dir("priv/temp/guardian_db_test") end)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  def get_token(token_id \\ "token-uuid"), do: Repo.get(Token.query_schema(), token_id)
end
