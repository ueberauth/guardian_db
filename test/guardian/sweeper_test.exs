defmodule Guardian.DB.SweeperTest do
  use Guardian.DB.TestSupport.CaseTemplate

  alias Guardian.DB.Token
  alias Guardian.DB.Sweeper

  describe "purge/0" do
    test "purges expired tokens" do
      Token.create(
        %{"jti" => "token1", "aud" => "token", "exp" => Guardian.timestamp() + 5000},
        "Token 1"
      )

      Token.create(
        %{"jti" => "token2", "aud" => "token", "exp" => Guardian.timestamp() - 5000},
        "Token 2"
      )

      {:ok, pid} = Sweeper.start_link(interval: 1_000_000_000)
      Sweeper.purge()

      GenServer.stop(pid)

      token1 = get_token("token1")
      token2 = get_token("token2")

      assert token1 != nil
      assert token2 == nil
    end
  end

  describe "reset_timer" do
    test "cancels and restarts the existing timer" do
      interval = 1_000_000_000
      {:ok, pid} = Sweeper.start_link(interval: interval)

      [interval: ^interval, timer: timer] = :sys.get_state(pid)

      Sweeper.reset_timer()

      [interval: _interval, timer: new_timer] = :sys.get_state(pid)

      assert timer != new_timer
    end
  end
end
