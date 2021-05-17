defmodule Guardian.DBFailTest do
  use Guardian.DB.TestSupport.CaseTemplate

  test "after_encode_and_sign_in is fails" do
    token = get_token()
    assert token == nil

    {:error, :token_storage_failure} =
      Guardian.DB.after_encode_and_sign(%{}, "token", %{}, "The JWT")

    token = get_token()
    assert token == nil
  end
end
