use Mix.Config

config :guardian, Guardian,
      issuer: "GuardianDb",
      secret_key: "woeirulkjosiujgwpeiojlkjw3prowiuefoskjd",
      serializer: Guardian.TestGuardianSerializer

config :guardian_db, GuardianDb,
       repo: GuardianDb.Test.Repo

config :guardian_db, ecto_repos: [GuardianDb.Test.Repo]

config :guardian_db, GuardianDb.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "dneighman",
  password: "",
  database: "guardian_db_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/test"
