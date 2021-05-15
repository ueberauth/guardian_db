defmodule Guardian.DB.Repo do
  @moduledoc """
  Defines a Guardian DB repository.

  The repostiroy behaviour allows to use any storage system for Guardian Tokens.
  """

  @type query :: Ecto.Query.t()
  @type schema :: Ecto.Schema.t()
  @type changeset :: Ecto.Changeset.t()
  @type schema_or_changeset :: schema() | changeset()
  @type queryable :: query() | schema()
  @type opts :: keyword()
  @type id :: pos_integer() | binary() | Ecto.UUID.t()

  @doc """
  Retrieves JWT token. Used in `Guardian.DB.Token.find_by_claims/1`.
  """
  @callback one(queryable()) :: schema() | nil

  @doc """
  Persists JWT token. Used in `Guardian.DB.Token.create/2`.
  """
  @callback insert(schema_or_changeset()) :: {:ok, schema()} | {:error, changeset()}

  @doc """
  Deletes JWT token. Used in `Guardian.DB.Token.destroy_token/3`.
  """
  @callback delete(schema_or_changeset(), opts()) :: {:ok, schema()} | {:error, changeset()}

  @doc """
  Purges all JWT tokens. Used in `Guardian.DB.Token.purge_expired_tokens/0 and
  in `Guardian.DB.Token.destroy_by_sub/1`. Returns a tuple containing the
  number of entries and any returned result as second element.
  """
  @callback delete_all(queryable(), opts()) :: {integer(), nil | [term()]}

  @doc false
  def repo do
    :guardian
    |> Application.fetch_env!(Guardian.DB)
    |> Keyword.fetch!(:repo)
  end
end
