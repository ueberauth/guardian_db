GuardianDb
==========

GuardianDB is an extension to vanilla Guardian that tracks tokens in your
application to prevent playback.

Installation
==========

GuardianDb assumes that you are using the Guardian framework for authentication.

To install GuardianDb, first add it to your `mix.exs` file:

```elixir
    defp deps do
      [
      # ...
      {:guardian_db, "~> 0.8.0"}
      # ...
      ]
    end
```

Then run `mix deps.get` on your terminal.

You will then need to add a migration:

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
          timestamps()
        end

      end

    end
```

**Do not run the migration yet.** You also need to add this to your configuration:

```elixir
    config :guardian, Guardian,
           hooks: GuardianDb,
           #…

    config :guardian_db, GuardianDb,
           repo: MyApp.Repo,
           schema_name: "guardian_tokens"
```

If you created the token table under a different name in your migration, you will need to specify that in the `schema_name` option above. For example, if your token table is named `auth_tokens` then the `schema_name` in your GuardianDb config also needs to say `auth_tokens`.

Now run the migration and you'll be good to go.

Usage
==========

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

Considerations
==========

Vanilla Guardian is already a very robust JWT solution. However, if your application needs the ability to immediately revoke and invalidate tokens that have already been generated, you need something like GuardianDb to build upon Guardian.

In vanilla Guardian, you as a systems administrator have no way of revoking tokens that have already been generated. You can call `Guardian.revoke!`, but in vanilla Guardian that function does not actually do anything - it just provides hooks for other libraries, such as this one, to define more specific behavior. Discarding the token away after something like a log out action is left up to the client application. If the client application does not discard the token, or does not log out, or the token gets stolen by a malicious script (because the client application stores it in localStorage, for instance), the only thing you can do is wait until the token expires. Depending on the scenario, this may not be acceptable.

With GuardianDb, records of all generated tokens are kept in your application's database. During each request, the `Guardian.Plug.VerifyHeader` and `Guardian.Plug.VerifySession` plugs check the database to make sure the token is there. If it is not, the server returns a 401 Unauthorized response to the client. Furthermore, `Guardian.revoke!` behavior becomes enhanced, as it actually removes the token from the database. This means that if the user logs out, or you revoke their token (e.g. after noticing suspicious activity on the account), they will need to re-authenticate.

### Disadvantages

In vanilla Guardian, token verification is very light-weight. The only thing Guardian does is decode incoming tokens and make sure they are valid. This can make it much easier to horizontally scale your application, since there is no need to centrally store sessions and make them available to load balancers or other servers.

With GuardianDb, every request requires a trip to the database, as Guardian now needs to ensure that a record of the token exists. In large scale applications this can be fairly costly, and can arguably eliminate the main advantage of using a JWT authentication solution, which is statelessness. Furthermore, session authentication already works this way, and in most cases there isn't a good enough reason to reinvent that wheel using JWTs.

In other words, once you have reached a point where you think you need GuardianDb, it may be time to take a step back and reconsider your whole approach to authentication!
