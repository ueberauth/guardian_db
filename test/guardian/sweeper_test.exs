defmodule Guardian.DB.Token.SweeperTest do
  use Guardian.DB.TestSupport.CaseTemplate

  alias Guardian.DB.Token
  alias Guardian.DB.Token.Sweeper

  test "purge stale tokens" do
    Token.create(
      %{"jti" => "token1", "aud" => "token", "exp" => Guardian.timestamp() + 5000},
      "Token 1"
    )

    Token.create(
      %{"jti" => "token2", "aud" => "token", "exp" => Guardian.timestamp() - 5000},
      "Token 2"
    )

    interval = 0
    state = %{interval: interval}
    new_state = Sweeper.sweep(state)

    token1 = get_token("token1")
    token2 = get_token("token2")

    assert token1 != nil
    assert token2 == nil

    assert new_state[:timer] != nil
    assert_receive :sweep, interval + 10
  end
end
