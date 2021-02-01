defmodule Guardian.DBFailTest do
  alias Guardian.DB.Token
  use Guardian.DB.TestSupport.CaseTemplate

  test "after_encode_and_sign_in is fails", context do
    token = get_token()
    assert token == nil

    {:error, :token_storage_failure} =
      Guardian.DB.after_encode_and_sign(%{}, "token", %{}, "The JWT")

    token = get_token()
    assert token == nil
  end
end
