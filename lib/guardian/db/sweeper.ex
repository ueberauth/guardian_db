defmodule Guardian.DB.Sweeper do
  @moduledoc """
  A GenServer that periodically checks for, and expires, tokens from storage.

  To leverage the automated Sweeper functionality update your project's Application
  file to include the following child in your supervision tree:

  ## Example

    worker(Guardian.DB.Sweeper, [interval: 60])
  """
  use GenServer

  alias Guardian.DB.Token

  @sixty_minutes 60 * 60 * 1000

  def start_link(opts) do
    interval = Keyword.get(opts, :interval, @sixty_minutes)
    GenServer.start_link(__MODULE__, [interval: interval], name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, schedule(state)}
  end

  @impl true
  def handle_cast(:reset_timer, state) do
    {:noreply, schedule(state)}
  end

  @impl true
  def handle_cast(:sweep, state) do
    Token.purge_expired_tokens()
    {:noreply, schedule(state)}
  end

  @impl true
  def handle_info(:sweep, state) do
    Token.purge_expired_tokens()
    {:noreply, schedule(state)}
  end

  def handle_info(_, state), do: {:noreply, state}

  @doc """
  Manually trigger a database purge of expired tokens. Also resets the current
  scheduled work.
  """
  def purge do
    GenServer.cast(__MODULE__, :sweep)
  end

  @doc """
  Reset the purge timer.
  """
  def reset_timer do
    GenServer.cast(__MODULE__, :reset_timer)
  end

  defp schedule(opts) do
    if timer = Keyword.get(opts, :timer), do: Process.cancel_timer(timer)

    interval = Keyword.get(opts, :interval)
    timer = Process.send_after(self(), :sweep, interval)

    [interval: interval, timer: timer]
  end
end
