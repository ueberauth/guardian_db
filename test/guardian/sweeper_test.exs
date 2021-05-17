defmodule Guardian.DB.SweeperTest do
  use Guardian.DB.TestSupport.CaseTemplate

  import Mox

  alias Guardian.DB.Token
  alias Guardian.DB.Sweeper

  setup :verify_on_exit!

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

  describe "handle_cast/2" do
    test "resets the timer" do
      ref = Process.send_after(__MODULE__, :sweep, 1_000_000_000)
      assert {:noreply, [interval: 1_000_000_000, timer: timer}} = Sweeper.handle_cast(:reset_timer, %{timer: ref, interval: 1_000_000_000})
      assert ref != timer
      assert is_reference(timer)

      Process.cancel_timer(timer)
    end

    test "triggers a sweep and resets the timer" do
      expect(Guardian.DB.MockAdapter, :purge_expired_tokens, fn _, _ ->
        {0, []}
      end)

      ref = Process.send_after(__MODULE__, :sweep, 1_000_000_000)
      assert {:noreply, [interval: 1_000_000_000, timer: timer}} = Sweeper.handle_cast(:sweep, %{timer: ref, interval: 1_000_000_000})
      assert ref != timer
      assert is_reference(timer)

      Process.cancel_timer(timer)
    end
  end

  describe "handle_info/2" do
    test "triggers a sweep and resets the timer" do
      expect(Guardian.DB.MockAdapter, :purge_expired_tokens, fn _, _ ->
        {0, []}
      end)

      ref = Process.send_after(__MODULE__, :sweep, 1_000_000_000)
      assert {:noreply, [interval: 1_000_000_000, timer: timer}} = Sweeper.handle_info(:sweep, %{timer: ref, interval: 1_000_000_000})
      assert ref != timer
      assert is_reference(timer)

      Process.cancel_timer(timer)
    end
  end
end
