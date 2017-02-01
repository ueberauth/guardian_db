GuardianDb
==========

GuardianDB is an extension to vanilla Guardian that tracks tokens in your
application to prevent playback.

All tokens are stored in the database when initially generated.
After that, each time they are verified, the token is looked up. If present, the
verification continues but if it is not found, the verification is abandoned
with an error response.

```elixir
    case Guardian.encode_and_sign(resource, type, claims) do
      {:ok, jwt, full_claims} -> # cool
      {:error, :token_storage_failure} -> # this comes from GuardianDb
      {:error, reason} -> # handle failure
    end

    case Guardian.decode_and_verify(jwt) do
      {:ok, claims} -> # stuff with the claims
      {:error, :token_not_found} -> # This comes from GuardianDb
      {:error, reason} -> # something else stopped us from verifying
    end
```

When you want to revoke a token, call Guardian.revoke!. This is called
automatically by Guardian when using the sign\_out function. But for times when
you're using an API.

```elixir
    case Guardian.revoke! jwt, claims do
      :ok -> # Great
      {:error, :could_not_revoke_token} -> # Oh no GuardianDb
      {:error, reason} -> # Oh no
    end
```

To use GuardianDb you'll need to add a migration

```elixir
    defmodule MyApp.Repo.Migrations.GuardianDb do
      use Ecto.Migration

      def change do

        create table(:guardian_tokens, primary_key: false) do
          add :jti, :string, primary_key: true
          add :aud, :string, primary_key: true
          add :typ, :string
          add :iss, :string
          add :sub, :string
          add :exp, :bigint
          add :jwt, :text
          add :claims, :map
          timestamps
        end

      end

    end
```

Add this to your configuration:

```elixir
    config :guardian, Guardian,
           hooks: GuardianDb,
           #…

    config :guardian_db, GuardianDb,
           repo: MyApp.Repo,
           schema_name: "tokens" # Optional, default is "guardian_tokens"
```

It's a good idea to purge out any stale tokens that have already expired.

```elixir
    GuardianDb.Token.purge_expired_tokens!
```

You can setup automatic purging by adding the `GuardianDb.ExpiredSweeper` as a worker to your supervision tree.

```elixir
  worker(GuardianDb.ExpiredSweeper, [])
```

If you are working with a production release using Distillery, you need to ensure both `guardian_db` and `distillery` are added to your applications list.

```elixir
  def application do
    [applications: :distillery, :guardian_db]
  end
```

To configure your sweeper add a `sweep_interval` in minutes to your
`guardian_db` config.


```elixir
    config :guardian_db, GuardianDb,
           repo: MyApp.Repo,
           sweep_interval: 120 # 120 minutes
```

By default GuardianDb will not purge your expired tokens.
