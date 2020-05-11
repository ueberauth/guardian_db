defmodule Guardian.DB do
  @moduledoc """
  `Guardian.DB` is a simple module that hooks into `Guardian` to prevent
  playback of tokens.

  In `Guardian`, tokens aren't tracked so the main mechanism that exists to
  make a token inactive is to set the expiry and wait until it arrives.

  `Guardian.DB` takes an active role and stores each token in the database
  verifying it's presense (based on it's jti) when `Guardian` verifies the
  token.
  If the token is not present in the DB, the `Guardian` token cannot be
  verified.

  Provides a simple database storage and check for `Guardian` tokens.

  - When generating a token, the token is stored in a database.
  - When tokens are verified (channel, session or header) the database is
  checked for an entry that matches. If none is found, verification results in
  an error.
  - When logout, or revoking the token, the corresponding entry is removed

  # Setup

  ### Config

  Add your configuration to your environment files. You need to specify

  * `repo`

  You may also configure

  * `prefix` - The schema prefix to use.
  * `schema_name` - The name of the schema to use. Default "guardian_tokens".
  * `sweep_interval` - The interval between db sweeps to remove old tokens.
  Default 60 (mins).

  ### Sweeper

  In order to sweep your expired tokens from the db, you'll need to add
  `Guardian.DB.Token.SweeperServer` to your supervision tree.
  In your supervisor add it as a worker

  ```elixir
  worker(Guardian.DB.Token.SweeperServer, [])
  ```

  # Migration

  `Guardian.DB` requires a table in your database. Create a migration like the
  following:

  ```elixir
    create table(:guardian_tokens, primary_key: false) do
      add(:jti, :string, primary_key: true)
      add(:typ, :string)
      add(:aud, :string)
      add(:iss, :string)
      add(:sub, :string)
      add(:exp, :bigint)
      add(:jwt, :text)
      add(:claims, :map)
      timestamps()
    end
  ```

  `Guardian.DB` works by hooking into the lifecycle of your token module.

  You'll need to add it to

  * `after_encode_and_sign`
  * `on_verify`
  * `on_revoke`

  For example:

  ```elixir
  defmodule MyApp.AuthTokens do
    use Guardian, otp_app: :my_app

    # snip...

    def after_encode_and_sign(resource, claims, token, _options) do
      with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
        {:ok, token}
      end
    end

    def on_verify(claims, token, _options) do
      with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
        {:ok, claims}
      end
    end

    def on_revoke(claims, token, _options) do
      with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
        {:ok, claims}
      end
    end
  end
  ```
  """

  alias Guardian.DB.Token

  @doc """
  After the JWT is generated, stores the various fields of it in the DB for
  tracking. If the token type does not match the configured types to be stored,
  the claims are passed through.
  """
  def after_encode_and_sign(resource, type, claims, jwt) do
    case store_token(type, claims, jwt) do
      {:error, _} -> {:error, :token_storage_failure}
      _ -> {:ok, {resource, type, claims, jwt}}
    end
  end

  defp store_token(type, claims, jwt) do
    if storable_type?(type) do
      Token.create(claims, jwt)
    else
      :ignore
    end
  end

  @doc """
  When a token is verified, check to make sure that it is present in the DB.
  If the token is found, the verification continues, if not an error is
  returned.
  If the type of the token does not match the configured token storage types,
  the claims are passed through.
  """
  def on_verify(claims, jwt) do
    case find_token(claims) do
      nil -> {:error, :token_not_found}
      _ -> {:ok, {claims, jwt}}
    end
  end

  defp find_token(%{"typ" => type} = claims) do
    if storable_type?(type) do
      Token.find_by_claims(claims)
    else
      :ignore
    end
  end

  @doc """
  When a token is refreshed, we invalidate the old token and add the new token
  in the DB.
  """
  def on_refresh({old_token, old_claims}, {new_token, new_claims}) do
    on_revoke(old_claims, old_token)
    after_encode_and_sign(%{}, new_claims["typ"], new_claims, new_token)

    {:ok, {old_token, old_claims}, {new_token, new_claims}}
  end

  @doc """
  When logging out, or revoking a token, removes from the database so the
  token may no longer be used.
  """
  def on_revoke(claims, jwt) do
    claims
    |> Token.find_by_claims()
    |> Token.destroy_token(claims, jwt)
  end

  @doc """
  Revoke all tokens of a given subject. Returns the amount of tokens revoked.

  ## Usage

  Add to your `Guardian` module.

  ```elixir
  defmodule MyApp.AuthTokens do
    use Guardian, otp_app: :my_app

    # snip...

    def revoke_all(resource, claims) do
      with {:ok, sub} <- subject_for_token(resource, claims) do
        Guardian.DB.revoke_all(resource)
      end
    end
  end
  ```

  Then you revoke all tokens of a resource.

  ```elixir
  MyApp.AuthTokens.revoke_all(resource, %{})
  ```

  """
  def revoke_all(sub) do
    {amount_deleted, _} = Token.destroy_by_sub(sub)

    {:ok, amount_deleted}
  end

  @doc false
  def repo do
    :guardian
    |> Application.fetch_env!(Guardian.DB)
    |> Keyword.fetch!(:repo)
  end

  defp token_types do
    :guardian
    |> Application.fetch_env!(Guardian.DB)
    |> Keyword.get(:token_types, [])
  end

  defp storable_type?(type), do: storable_type?(type, token_types())

  # Store all types by default
  defp storable_type?(_, []), do: true
  defp storable_type?(type, types), do: type in types
end
