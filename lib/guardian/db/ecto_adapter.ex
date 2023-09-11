defmodule Guardian.DB.EctoAdapter do
  @moduledoc """
  Implement the Guardian.DB.Adapter for Ecto.Repo
  """

  import Ecto.Query

  alias Guardian.DB.Token

  @behaviour Guardian.DB.Adapter

  @default_schema_name "guardian_tokens"

  @impl true
  def one(claims, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    repo = Keyword.get(opts, :repo)

    jti = Map.get(claims, "jti")
    aud = Map.get(claims, "aud")

    opts
    |> query_schema()
    |> where([token], token.jti == ^jti and token.aud == ^aud)
    |> repo.one(prefix: prefix)
  end

  @impl true
  def insert(changeset, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    repo = Keyword.get(opts, :repo)

    data =
      changeset
      |> Map.get(:data)
      |> Ecto.put_meta(source: schema_name(opts))
      |> Ecto.put_meta(prefix: prefix)

    changeset = %{changeset | data: data}

    repo.insert(changeset, prefix: prefix)
  end

  @impl true
  def delete(record, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    repo = Keyword.get(opts, :repo)

    repo.delete(record, prefix: prefix, stale_error_field: :stale_token)
  end

  @impl true
  def delete_by_sub(sub, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    repo = Keyword.get(opts, :repo)

    opts
    |> query_schema()
    |> where([token], token.sub == ^sub)
    |> repo.delete_all(prefix: prefix)
  end

  @impl true
  def purge_expired_tokens(timestamp, opts) do
    prefix = Keyword.get(opts, :prefix, nil)
    repo = Keyword.get(opts, :repo)

    opts
    |> query_schema()
    |> where([token], token.exp < ^timestamp)
    |> repo.delete_all(prefix: prefix)
  end

  defp query_schema(opts) do
    {schema_name(opts), Token}
  end

  defp schema_name(opts) do
    Keyword.get(opts, :schema_name, @default_schema_name)
  end
end
