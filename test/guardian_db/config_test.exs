defmodule GuardianDb.ConfigTest do
  use GuardianDb.TestCase

  alias GuardianDb.Token
  alias GuardianDb.Test.Repo

  @moduletag :config_test

  defp persist_token _ do
    { :ok, %{
        claims: %{
          "typ" => "persist_token",
          "jti" => "persist-uuid",
          "aud" => "token",
          "sub" => "the_subject",
          "iss" => "the_issuer",
          "exp" => Guardian.Utils.timestamp() + 1_000_000_000,
        }
      }
    }
  end

  defp ephemeral_token _ do
    { :ok, %{
        claims: %{
          "typ" => "ephemeral_token",
          "jti" => "ephemeral-uuid",
          "aud" => "token",
          "sub" => "the_subject",
          "iss" => "the_issuer",
          "exp" => Guardian.Utils.timestamp() + 1_000_000_000,
        }
      }
    }
  end

  describe "with token type not found in :token_types" do
    setup [:ephemeral_token]

    test "after_encode_and_sign_in is successful, do not persist token", context do
      token = Repo.get(Token, "ephemeral-uuid")
      assert token == nil

      GuardianDb.after_encode_and_sign(%{}, :ephemeral_token, context.claims, "The JWT")

      token = Repo.get(Token, "ephemeral-uuid")
      assert token == nil
    end

    test "on_verify without a record in the db, do not halt", context do
      token = Repo.get(Token, "ephemeral-uuid")
      assert token == nil
      assert {:ok, {context.claims, "The JWT"}} == GuardianDb.on_verify(context.claims, "The JWT")
    end

    test "on_revoke without a record in the db", context do
      token = Repo.get(Token, "ephemeral-uuid")
      assert token == nil
      assert GuardianDb.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}
    end

    test "on_revoke with a record in the db, still delete db record", context do
      Token.create! context.claims, "The JWT"

      token = Repo.get(Token, "ephemeral-uuid")
      assert token != nil

      assert GuardianDb.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}

      token = Repo.get(Token, "ephemeral-uuid")
      assert token == nil
    end
  end

  describe "with matching token type defined in :token_types" do
    setup [:persist_token]

    test "after_encode_and_sign_in is successful", context do
      token = Repo.get(Token, "persist-uuid")
      assert token == nil

      GuardianDb.after_encode_and_sign(%{}, :persist_token, context.claims, "The JWT")

      token = Repo.get(Token, "persist-uuid")

      assert token != nil
      assert token.typ == "persist_token"
      assert token.jti == "persist-uuid"
      assert token.aud == "token"
      assert token.sub == "the_subject"
      assert token.iss == "the_issuer"
      assert token.exp == context.claims["exp"]
      assert token.claims == context.claims
    end

    test "on_verify with a record in the db", context do
      Token.create! context.claims, "The JWT"
      token = Repo.get(Token, "persist-uuid")
      assert token != nil

      assert {:ok, {context.claims, "The JWT"}} == GuardianDb.on_verify(context.claims, "The JWT")
    end

    test "on_verify without a record in the db", context do
      token = Repo.get(Token, "persist-uuid")
      assert token == nil
      assert {:error, :token_not_found} == GuardianDb.on_verify(context.claims, "The JWT")
    end

    test "on_revoke without a record in the db", context do
      token = Repo.get(Token, "persist-uuid")
      assert token == nil
      assert GuardianDb.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}
    end

    test "on_revoke with a record in the db", context do
      Token.create! context.claims, "The JWT"

      token = Repo.get(Token, "persist-uuid")
      assert token != nil

      assert GuardianDb.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}

      token = Repo.get(Token, "persist-uuid")
      assert token == nil
    end
  end
end
