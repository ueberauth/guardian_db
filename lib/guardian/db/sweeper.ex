defmodule Guardian.DB.Sweeper do
  @moduledoc """
  A GenServer that periodically checks for, and expires, tokens from storage.

  To leverage the automated Sweeper functionality update your project's Application
  file to include the following child in your supervision tree:

  * `interval` - The interval between db sweeps to remove old tokens, in
  milliseconds. Defaults to 1 hour.

  ## Example

  ```elixir
    worker(Guardian.DB.Sweeper, [interval: 60 * 60 * 1000])
  ```
  """
  use GenServer

  alias Guardian.DB.Token

  @sixty_minutes 60

  def start_link(opts) do
    interval = Keyword.get(opts, :interval, @sixty_minutes) |> minute_to_ms()
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

  defp minute_to_ms(value) when is_binary(value) do
    value
    |> String.to_integer()
    |> minute_to_ms()
  end

  defp minute_to_ms(value) when value < 1, do: 1000
  defp minute_to_ms(value), do: round(value * 60 * 1000)
end
