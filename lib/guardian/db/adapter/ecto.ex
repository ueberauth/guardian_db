defmodule Guardian.DB.EctoAdapter do
  @moduledoc """
  Implement the Guardian.DB.Adapter for Ecto.Repo
  """

  import Ecto.Query

  alias Guardian.DB.Token

  @behaviour Guardian.DB.Adapter

  @impl true
  def one(claims, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    jti = Map.get(claims, "jti")
    aud = Map.get(claims, "aud")

    query_schema()
    |> where([token], token.jti == ^jti and token.aud == ^aud)
    |> ecto_repo().one(prefix: prefix)
  end

  @impl true
  def insert(changeset, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    ecto_repo().insert(changeset, prefix: prefix)
  end

  @impl true
  def delete(record, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    ecto_repo().delete(record, prefix: prefix)
  end

  @impl true
  def delete_by_sub(sub, opts) do
    prefix = Keyword.get(opts, :prefix, nil)

    query_schema()
    |> where([token], token.sub == ^sub)
    |> ecto_repo().delete_all(prefix: prefix)
  end

  @impl true
  def purge_expired_tokens(timestamp, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    timestamp = Guardian.timestamp()

    query_schema()
    |> where([token], token.exp < ^timestamp)
    |> ecto_repo().delete_all(prefix: prefix)
  end

  @doc false
  def query_schema do
    {schema_name(), Token}
  end

  @doc false
  def schema_name do
    :guardian
    |> Application.fetch_env!(Guardian.DB)
    |> Keyword.get(:schema_name, "guardian_tokens")
  end

  def ecto_repo do
    :guardian
    |> Application.fetch_env!(Guardian.DB)
    |> Keyword.fetch!(:repo)
  end
end
