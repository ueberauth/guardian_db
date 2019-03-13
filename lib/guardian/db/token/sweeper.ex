defmodule Guardian.DB.Token.Sweeper do
  @moduledoc """
  Purges and schedule work for cleaning up expired tokens.
  """

  alias Guardian.DB.Token

  @doc """
  Purges the expired tokens and schedule the next purge.
  """
  def sweep(state) do
    Token.purge_expired_tokens()
    schedule_work(state)
  end

  @doc """
  Schedule the next purge.
  """
  def schedule_work(state) do
    if state[:timer] do
      Process.cancel_timer(state.timer)
    end

    timer = Process.send_after(self(), :sweep, state[:interval])
    Map.merge(state, %{timer: timer})
  end

  @doc false
  def get_interval do
    :guardian
    |> Application.get_env(Guardian.DB)
    |> Keyword.get(:sweep_interval, 60)
    |> minute_to_ms()
  end

  defp minute_to_ms(value) when is_binary(value) do
    value
    |> String.to_integer()
    |> minute_to_ms()
  end

  defp minute_to_ms(value) when value < 1, do: 1000
  defp minute_to_ms(value), do: round(value * 60 * 1000)
end
