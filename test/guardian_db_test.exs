defmodule GuardianDbTest do
  use GuardianDb.Test.DataCase
  alias GuardianDb.Token

  defp get_token(token_id \\ "token-uuid"), do: Repo.get(Token.query_schema(), token_id)

  setup do
    {:ok, %{
        claims: %{
          "jti" => "token-uuid",
          "aud" => "token",
          "sub" => "the_subject",
          "iss" => "the_issuer",
          "exp" => Guardian.timestamp() + 1_000_000_000,
        }
      }
    }
  end

  test "after_encode_and_sign_in is successful", context do
    token = get_token()
    assert token == nil

    GuardianDb.after_encode_and_sign(%{}, :token, context.claims, "The JWT")

    token = get_token()

    assert token != nil
    assert token.jti == "token-uuid"
    assert token.aud == "token"
    assert token.sub == "the_subject"
    assert token.iss == "the_issuer"
    assert token.exp == context.claims["exp"]
    assert token.claims == context.claims
  end

  test "on_verify with a record in the db", context do
    Token.create! context.claims, "The JWT"
    token = get_token()
    assert token != nil

    assert {:ok, {context.claims, "The JWT"}} == GuardianDb.on_verify(context.claims, "The JWT")
  end

  test "on_verify without a record in the db", context do
    token = get_token()
    assert token == nil
    assert {:error, :token_not_found} == GuardianDb.on_verify(context.claims, "The JWT")
  end

  test "on_revoke without a record in the db", context do
    token = get_token()
    assert token == nil
    assert GuardianDb.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}
  end

  test "on_revoke with a record in the db", context do
    Token.create! context.claims, "The JWT"

    token = get_token()
    assert token != nil

    assert GuardianDb.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}

    token = get_token()
    assert token == nil
  end

  test "purge stale tokens" do
    Token.create! %{"jti" => "token1", "exp" => Guardian.timestamp + 5000}, "Token 1"
    Token.create! %{"jti" => "token2", "exp" => Guardian.timestamp - 5000}, "Token 2"

    Token.purge_expired_tokens!

    token1 = get_token("token1")
    token2 = get_token("token2")
    assert token1 != nil
    assert token2 == nil
  end
end
