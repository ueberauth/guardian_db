defmodule Guardian.DBTest do
  use Guardian.DB.TestSupport.CaseTemplate
  alias Guardian.DB.Token

  setup do
    {:ok,
     %{
       claims: %{
         "jti" => "token-uuid",
         "typ" => "token",
         "aud" => "token",
         "sub" => "the_subject",
         "iss" => "the_issuer",
         "exp" => Guardian.timestamp() + 1_000_000_000
       }
     }}
  end

  test "after_encode_and_sign_in is successful", context do
    token = get_token()
    assert token == nil

    Guardian.DB.after_encode_and_sign(%{}, "token", context.claims, "The JWT")

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
    Token.create(context.claims, "The JWT")
    token = get_token()
    assert token != nil

    assert {:ok, {context.claims, "The JWT"}} == Guardian.DB.on_verify(context.claims, "The JWT")
  end

  test "on_verify without a record in the db", context do
    token = get_token()
    assert token == nil
    assert {:error, :token_not_found} == Guardian.DB.on_verify(context.claims, "The JWT")
  end

  test "on_refresh without a record in the db", context do
    token = get_token()
    assert token == nil

    Guardian.DB.after_encode_and_sign(%{}, "token", context.claims, "The JWT 1")
    old_stuff = {get_token(), context.claims}

    new_claims = %{
      "jti" => "token-uuid1",
      "typ" => "token",
      "aud" => "token",
      "sub" => "the_subject",
      "iss" => "the_issuer",
      "exp" => Guardian.timestamp() + 2_000_000_000
    }

    Guardian.DB.after_encode_and_sign(%{}, "token", new_claims, "The JWT 2")
    new_stuff = {get_token("token-uuid1"), new_claims}

    assert Guardian.DB.on_refresh(old_stuff, new_stuff) == {:ok, old_stuff, new_stuff}
  end

  test "on_revoke without a record in the db", context do
    token = get_token()
    assert token == nil
    assert Guardian.DB.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}
  end

  test "on_revoke with a record in the db", context do
    Token.create(context.claims, "The JWT")

    token = get_token()
    assert token != nil

    assert Guardian.DB.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}

    token = get_token()
    assert token == nil
  end

  test "purge stale tokens" do
    Token.create(
      %{"jti" => "token1", "aud" => "token", "exp" => Guardian.timestamp() + 5000},
      "Token 1"
    )

    Token.create(
      %{"jti" => "token2", "aud" => "token", "exp" => Guardian.timestamp() - 5000},
      "Token 2"
    )

    Token.purge_expired_tokens()

    token1 = get_token("token1")
    token2 = get_token("token2")
    assert token1 != nil
    assert token2 == nil
  end
end
