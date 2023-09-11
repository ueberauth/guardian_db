defmodule Guardian.DB.Adapter do
  @moduledoc """
  The Guardian DB Adapter.

  This behaviour allows to use any storage system
  for Guardian Tokens.
  """


  @typep schema :: Ecto.Schema.t()
  @typep changeset :: Ecto.Changeset.t()
  @typep schema_or_changeset :: schema() | changeset()
  @typep claims :: map()
  @typep exp :: pos_integer()
  @typep sub :: binary()
  @typep opts :: keyword()


  @doc """
  Retrieves JWT token
  Used in `Guardian.DB.Token.find_by_claims/1`
  """
  @callback one(claims(), opts()) :: schema() | nil

  @doc """
  Persists JWT token
  Used in `Guardian.DB.Token.create/2`
  """
  @callback insert(schema_or_changeset(), opts()) :: {:ok, schema()} | {:error, changeset()}

  @doc """
  Deletes JWT token
  Used in `Guardian.DB.Token.destroy_token/3`
  """
  @callback delete(schema_or_changeset(), opts()) :: {:ok, schema()} | {:error, changeset()}

  @doc """
  Purges all JWT tokens for a given subject.

  Returns a tuple containing the number of entries and any returned result as second element.
  """
  @callback delete_by_sub(sub(), opts()) :: {integer(), nil | [term()]}

  @doc """
  Purges all expired JWT tokens.

  Returns a tuple containing the number of entries and any returned result as second element.
  """
  @callback purge_expired_tokens(exp(), opts()) :: {integer(), nil | [term()]}
end
