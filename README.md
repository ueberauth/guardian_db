GuardianDb
==========

GuardianDB is an extension to vanilla Guardian that tracks tokens in your
application's database to prevent playback.

Support for `Guardian` 0.14.x is via the 0.8 release.

Installation
==========

GuardianDb assumes that you are using the Guardian framework for authentication.

To install GuardianDb, first add it to your `mix.exs` file:

```elixir
    defp deps do
      [
      # ...
      {:guardian_db, "~> 1.0.0"}
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

**Do not run the migration yet,** we need to complete our setup first.

# Configuration

```elixir
  config :guardian_db, GuardianDb,
         repo: MyApp.Repo,
         schema_name: "guardian_tokens", # default
         sweep_interval: 60 # default: 60 minutes
```

To sweep expired tokens from your db you should add `GuardianDb.ExpiredSweeper` to your supervision tree.

```elixir
  worker(GuardianDb.ExpiredSweeper, [])
```

`GuardianDb` works by hooking into the lifecycle of your token module.

You'll need to add it to:

* `after_encode_and_sign`
* `on_verify`
* `on_revoke`

For example:

```elixir
defmodule MyApp.AuthTokens do
  use Guardian, otp_app: :my_app

  # snip...

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- GuardianDb.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- GuardianDb.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- GuardianDb.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
```

Now run the migration and you'll be good to go.

Considerations
==========

Vanilla Guardian is already a very robust JWT solution. However, if your application needs the ability to immediately revoke and invalidate tokens that have already been generated, you need something like GuardianDb to build upon Guardian.

In vanilla Guardian, you as a systems administrator have no way of revoking tokens that have already been generated. You can call `Guardian.revoke!`, but in vanilla Guardian that function does not actually do anything - it just provides hooks for other libraries, such as this one, to define more specific behavior. Discarding the token after something like a log out action is left up to the client application. If the client application does not discard the token, or does not log out, or the token gets stolen by a malicious script (because the client application stores it in localStorage, for instance), the only thing you can do is wait until the token expires. Depending on the scenario, this may not be acceptable.

With GuardianDb, records of all generated tokens are kept in your application's database. During each request, the `Guardian.Plug.VerifyHeader` and `Guardian.Plug.VerifySession` plugs check the database to make sure the token is there. If it is not, the server returns a 401 Unauthorized response to the client. Furthermore, `Guardian.revoke!` behavior becomes enhanced, as it actually removes the token from the database. This means that if the user logs out, or you revoke their token (e.g. after noticing suspicious activity on the account), they will need to re-authenticate.

### Disadvantages

In vanilla Guardian, token verification is very light-weight. The only thing Guardian does is decode incoming tokens and make sure they are valid. This can make it much easier to horizontally scale your application, since there is no need to centrally store sessions and make them available to load balancers or other servers.

With GuardianDb, every request requires a trip to the database, as Guardian now needs to ensure that a record of the token exists. In large scale applications this can be fairly costly, and can arguably eliminate the main advantage of using a JWT authentication solution, which is statelessness. Furthermore, session authentication already works this way, and in most cases there isn't a good enough reason to reinvent that wheel using JWTs.

In other words, once you have reached a point where you think you need GuardianDb, it may be time to take a step back and reconsider your whole approach to authentication!
