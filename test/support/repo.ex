defmodule Guardian.DB.TestSupport.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :guardian_db,
    adapter: Ecto.Adapters.Postgres

  def log(_cmd), do: nil
end
