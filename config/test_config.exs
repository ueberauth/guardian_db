use Mix.Config

import_config "test.exs"

config :guardian_db, GuardianDb,
       repo: GuardianDb.Test.Repo,
       token_types: [:persist_token]
