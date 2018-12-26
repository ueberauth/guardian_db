defmodule Guardian.DB.Test.Serializer do
  @moduledoc false

  use Guardian, otp_app: :guardian_db

  def subject_for_token(resource, _claims) do
    {:ok, resource}
  end

  def resource_from_claims(claims) do
    {:ok, claims["sub"]}
  end
end
