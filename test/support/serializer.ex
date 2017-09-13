defmodule GuardianDb.Test.Serializer do
  @behaviour Guardian.Serializer

  def for_token(sub), do: {:ok, sub}
  def from_token(sub), do: {:ok, sub}
end
