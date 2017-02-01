defmodule GuardianDb.ExpiredSweeper do
  @moduledoc """
  Periocially purges expired tokens from the DB.

  ## Example
    config :guardian_db, GuardianDb,
      sweep_interval: 60 # 1 hour

    # in your supervisor
      worker(GuardianDb.ExpiredSweeper, [])
  """
  use GenServer

  def start_link, do: start_link([])

  def start_link(state, _opts \\ []) do
    state = Enum.into(state, %{})

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Reset the purge timer.
  """
  def reset_timer! do
    GenServer.call(__MODULE__, :reset_timer)
  end

  @doc """
  Manually trigger a db purge of expired tokens.
  Also resets the current timer.
  """
  def purge! do
    GenServer.call(__MODULE__, :sweep)
  end

  def init(state) do
    {:ok, reset_state_timer!(state)}
  end

  def handle_call(:reset_timer, _from, state) do
    {:reply, :ok, reset_state_timer!(state)}
  end

  def handle_call(:sweep, _from, state) do
    {:reply, :ok, sweep!(state)}
  end

  def handle_info(:sweep, state) do
    {:noreply, sweep!(state)}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  defp sweep!(state) do
    GuardianDb.Token.purge_expired_tokens!
    reset_state_timer!(state)
  end

  defp reset_state_timer!(state) do
    if state[:timer] do
      Process.cancel_timer(state.timer)
    end

    timer = Process.send_after(self(), :sweep, interval())
    Map.merge(state, %{timer: timer})
  end

  defp interval do
    :guardian_db
    |> Application.get_env(GuardianDb)
    |> Keyword.get(:sweep_interval, 60)
    |> minute_to_ms
  end

  defp minute_to_ms(value) when value < 1, do: 1000
  defp minute_to_ms(value), do: round(value * 60 * 1000)
end
