use Mix.Config

config :guardian, Guardian.DB,
  issuer: "GuardianDB",
  secret_key: "HcdlxxmyDRvfrwdpjUPh2M8mWP+KtpOQK1g6fT5SHrnflSY8KiWeORqN6IZSJYTA",
  repo: Guardian.DB.TestSupport.Repo

config :guardian_db, ecto_repos: [Guardian.DB.TestSupport.Repo]

config :guardian_db, Guardian.DB.TestSupport.Repo,
  database: "guardian_db_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/temp/guardian_db_test"
