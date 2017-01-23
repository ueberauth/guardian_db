use Mix.Config

config :guardian_db, GuardianDb, repo: %{}

import_config "#{Mix.env}.exs"
