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
