defmodule Guardian.DB.Test.Repo do
  use Ecto.Repo, otp_app: :guardian_db

  def log(_cmd), do: nil
end
