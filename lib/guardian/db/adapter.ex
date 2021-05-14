defmodule Guardian.DB.Adapter do
  @moduledoc """
  The Guardian DB Adapter.

  This behaviour allows to use any storage system
  for Guardian Tokens.
  """

  @typep query :: Ecto.Query.t()
  @typep schema :: Ecto.Schema.t()
  @typep schema_or_changeset :: schema() | Ecto.Changeset.t()
  @typep queryable :: query() | schema()
  @typep opts :: keyword()
  @typep id :: pos_integer() | binary() | Ecto.UUID.t()

  @doc """
  Retrieves JWT token
  Used in `Guardian.DB.Token.find_by_claims/1`
  """
  @callback one(queryable()) :: nil | schema()

  @doc """
  Persists JWT token
  Used in `Guardian.DB.Token.create/2`
  """
  @callback insert(schema_or_changeset()) :: {:ok, schema()}

  @doc """
  Deletes JWT token
  Used in `Guardian.DB.Token.destroy_token/3`
  """
  @callback delete(schema_or_changeset()) :: {:ok, schema()}

  @doc """
  Deletes all JWT tokens of a user
  Used in `Guardian.DB.Token.destroy_by_sub/1`
  """
  @callback delete_all(queryable()) :: {:ok, pos_integer()}

  @doc """
  Purges all JWT tokens
  Used in `Guardian.DB.Token.purge_expired_tokens/0
  """
  @callback delete_all(queryable(), opts()) :: {:ok, pos_integer()}
end
