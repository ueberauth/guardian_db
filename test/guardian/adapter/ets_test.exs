defmodule Guardian.DB.ETSAdapterTest do
  use ExUnit.Case

  alias Guardian.DB.ETSAdapter, as: Adapter
  alias Guardian.DB.Token

  setup_all do
    {:ok, table: :ets.new(:guardian_db_test, [:set, :public])}
  end

  describe "insert/2" do
    test "creates a new row and returns the token", %{table: table} do
      claims = %{
        "jti" => "token-jti-insert-test",
        "typ" => "token-typ",
        "aud" => "token-aud",
        "sub" => "token-aub",
        "iss" => "token-iss",
        "exp" => Guardian.timestamp() + 1_000_000_000
      }

      assert {:ok, %{jti: "token-jti-insert-test", jwt: "test-jwt"}} =
               claims
               |> Token.changeset("test-jwt")
               |> Adapter.insert(table: table)
    end
  end

  describe "one/2" do
    test "returns the token by claims", %{table: table} do
      token = %Token{
        aud: "token-aud",
        exp: Guardian.timestamp() + 1_000_000_000,
        jti: "token-jti-one-test",
        sub: "token-sub"
      }

      :ets.insert(table, {token.jti, token.aud, token.sub, token.exp, token})

      assert %Token{} =
               Adapter.one(%{"aud" => "token-aud", "jti" => "token-jti-one-test"}, table: table)
    end
  end

  describe "delete/2" do
    test "deletes and returns the token", %{table: table} do
      token = %Token{
        aud: "token-aud",
        exp: Guardian.timestamp() + 1_000_000_000,
        jti: "token-jti-delete-test",
        sub: "token-sub"
      }

      :ets.insert(table, {token.jti, token.aud, token.sub, token.exp, token})

      assert {:ok, %Token{}} = Adapter.delete(token, table: table)

      assert [] = :ets.match(table, {token.jti, :_, :_, :"$1"})
    end
  end

  describe "delete_by_sub/2" do
    test "deletes many tokens by the subject", %{table: table} do
      one = %Token{
        aud: "token-aud",
        exp: Guardian.timestamp() + 1_000_000_000,
        jti: "token-jti-delete-by-sub-test1",
        sub: "subject"
      }

      two = %Token{
        aud: "token-aud",
        exp: Guardian.timestamp() + 1_000_000_000,
        jti: "token-jti-delete-by-sub-test2",
        sub: "subject"
      }

      :ets.insert(table, {one.jti, one.aud, one.sub, one.exp, one})
      :ets.insert(table, {two.jti, two.aud, two.sub, two.exp, two})

      assert {2, [%Token{}, %Token{}]} = Adapter.delete_by_sub("subject", table: table)

      assert [] = :ets.match(table, {:_, :_, "subject", :"$1"})
    end
  end

  describe "purge_expired_tokens/2" do
    test "deletes all tokens older than expiration", %{table: table} do
      one = %Token{
        aud: "token-aud",
        exp: 1,
        jti: "token-jti-purge-test1",
        sub: "token-sub"
      }

      two = %Token{
        aud: "token-aud",
        exp: Guardian.timestamp() + 1_000_000_000,
        jti: "token-jti-purge-test2",
        sub: "token-sub"
      }

      :ets.insert(table, {one.jti, one.aud, one.sub, one.exp, one})
      :ets.insert(table, {two.jti, two.aud, two.sub, two.exp, two})

      assert {1, [%Token{jti: "token-jti-purge-test1"}]} =
               Adapter.purge_expired_tokens(Guardian.timestamp(), table: table)
    end
  end
end
