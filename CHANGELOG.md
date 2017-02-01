# v0.8.0

* Sweeper configuration now works in minutes
* Update dependencies
* Fix 1.4 warnings
* Raise error when configuration is missing

# v0.7.0

* Add a schema prefix
* Add an expired token sweeper process

# v 0.6.0

### Breaking

* Add support for ecto 2 rc

# v 0.5.0

* Updated to support Guardian 0.10
* Make Postgrex optional
* Support database schema configuration
* Improve scope token lookup

# v 0.4.0

* Update deps to use higher level of postgrex
* Add the typ field

When migrating form 0.3.0 to 0.4.0 you'll need to run a migration to add the typ
field.

```elixir
alter table(:guardian_tokens) do
  add :typ, :string
end
```

# v 0.3.0

Update the schema to use a map for claims.

To update you'll need to change your schema.

```
mix ecto.gen.migration update_guardian_db_tokens

alter table(:guardian_tokens) do
  remove :claims
  add :claims, :map
end
```

# V 0.1.0

Initial release
