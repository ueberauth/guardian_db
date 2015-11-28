use Mix.Config

config :guardian, Guardian,
      issuer: "GuardianDb",
      secret_key: "woeirulkjosiujgwpeiojlkjw3prowiuefoskjd",
      serializer: Guardian.TestGuardianSerializer

