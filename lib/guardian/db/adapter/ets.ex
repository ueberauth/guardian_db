defmodule Guardian.DB.ETSAdapter do
  @moduledoc """
  Implement the Guardian.DB.Adapter for ETS
  """

  @behaviour Guardian.DB.Adapter

  @impl true
  def one(claims, opts) do
    jti = Map.get(claims, "jti")
    aud = Map.get(claims, "aud")

    match =
      opts
      |> Keyword.fetch!(:table)
      |> :ets.match({jti, aud, :_, :_, :"$1"})

    case match do
      [[token]] -> token
      _ -> nil
    end
  end

  @impl true
  def insert(%{valid?: true} = changeset, opts) do
    table = Keyword.fetch!(opts, :table)
    token = Map.merge(changeset.data, changeset.changes)

    unless :ets.insert(table, {token.jti, token.aud, token.sub, token.exp, token}) do
      raise """
      An error occurred trying to insert a new record into the ETS table #{table}. 

      Please ensure you've created the table before attempting to insert records.
      """
    end

    {:ok, token}
  end

  def insert(changeset, _opts) do
    {:error, changeset}
  end

  @impl true
  def delete(%{jti: jti} = token, opts) do
    table = Keyword.fetch!(opts, :table)

    if :ets.delete(table, jti) do
      {:ok, token}
    else
      {:error, token}
    end
  end

  @impl true
  def delete_by_sub(sub, opts) do
    table = Keyword.fetch!(opts, :table)

    table
    |> :ets.match({:"$1", :_, sub, :_, :"$2"})
    |> delete_many(table)
  end

  @impl true
  def purge_expired_tokens(exp, opts) do
    table = Keyword.fetch!(opts, :table)
    matcher = [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:<, :"$4", exp}], [[:"$1", :"$5"]]}]

    table
    |> :ets.select(matcher)
    |> delete_many(table)
  end

  defp expired_tokens({_jti, _aud, _sub, token}, exp), do: token.exp < exp

  defp delete_many(tokens, table) do
    deleted_tokens =
      Enum.reduce(tokens, [], fn [jti, token], acc ->
        if :ets.delete(table, jti) do
          [token | acc]
        else
          acc
        end
      end)

    {length(deleted_tokens), deleted_tokens}
  end
end
