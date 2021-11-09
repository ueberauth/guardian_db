defmodule Guardian.DB.SweeperTest do
  use ExUnit.Case

  import Mox

  alias Guardian.DB.{Sweeper, Token}

  setup_all context do
    config = Application.get_env(:guardian, Guardian.DB)

    Application.put_env(
      :guardian,
      Guardian.DB,
      Keyword.put(config, :adapter, Guardian.DB.MockAdapter)
    )

    on_exit(fn ->
      Application.put_env(:guardian, Guardian.DB, config)
    end)

    {:ok, context}
  end

  describe "handle_cast/2" do
    setup :verify_on_exit!

    test "resets the timer" do
      ref = Process.send_after(__MODULE__, :sweep, 1_000_000_000)

      assert {:noreply, [interval: 1_000_000_000, timer: timer]} =
               Sweeper.handle_cast(:reset_timer, timer: ref, interval: 1_000_000_000)

      assert ref != timer
      assert is_reference(timer)

      Process.cancel_timer(timer)
    end

    test "triggers a sweep and resets the timer" do
      expect(Guardian.DB.MockAdapter, :purge_expired_tokens, fn _, _ ->
        {0, []}
      end)

      ref = Process.send_after(__MODULE__, :sweep, 1_000_000_000)

      assert {:noreply, [interval: 1_000_000_000, timer: timer]} =
               Sweeper.handle_cast(:sweep, timer: ref, interval: 1_000_000_000)

      assert ref != timer
      assert is_reference(timer)

      Process.cancel_timer(timer)
    end
  end

  describe "handle_info/2" do
    setup :verify_on_exit!

    test "triggers a sweep and resets the timer" do
      expect(Guardian.DB.MockAdapter, :purge_expired_tokens, fn _, _ ->
        {0, []}
      end)

      ref = Process.send_after(__MODULE__, :sweep, 1_000_000_000)

      assert {:noreply, [interval: 1_000_000_000, timer: timer]} =
               Sweeper.handle_info(:sweep, timer: ref, interval: 1_000_000_000)

      assert ref != timer
      assert is_reference(timer)

      Process.cancel_timer(timer)
    end
  end
end
