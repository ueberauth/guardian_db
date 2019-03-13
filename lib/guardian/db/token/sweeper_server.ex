defmodule Guardian.DB.Token.SweeperServer do
  @moduledoc """
  Periocially purges expired tokens from the DB.

  ## Example
    config :guardian, Guardian.DB,
      sweep_interval: 60 # 1 hour

    # in your supervisor
      worker(Guardian.DB.Token.SweeperServer, [])
  """

  use GenServer
  alias Guardian.DB.Token.Sweeper

  def start_link(opts \\ []) do
    defaults = %{
      interval: Sweeper.get_interval()
    }

    state = Enum.into(opts, defaults)

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Reset the purge timer.
  """
  def reset_timer do
    GenServer.call(__MODULE__, :reset_timer)
  end

  @doc """
  Manually trigger a database purge of expired tokens. Also resets the current
  scheduled work.
  """
  def purge do
    GenServer.call(__MODULE__, :sweep)
  end

  def init(state) do
    {:ok, Sweeper.schedule_work(state)}
  end

  def handle_call(:reset_timer, _from, state) do
    {:reply, :ok, Sweeper.schedule_work(state)}
  end

  def handle_call(:sweep, _from, state) do
    {:reply, :ok, Sweeper.sweep(state)}
  end

  def handle_info(:sweep, state) do
    {:noreply, Sweeper.sweep(state)}
  end

  def handle_info(_, state), do: {:noreply, state}
end
