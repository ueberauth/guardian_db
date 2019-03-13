defmodule Guardian.DB.TestSupport.FileHelpers do
  @moduledoc false

  def tmp_path do
    Path.expand("../../priv/temp", __DIR__)
  end

  def tmp_path(path) do
    Path.expand("../../#{path}", __DIR__)
  end

  def create_dir(path) do
    run_if_abs_path(&File.mkdir_p!/1, path)
  end

  def destroy_dir(path) do
    run_if_abs_path(&File.rm_rf!/1, path)
  end

  defp run_if_abs_path(fun, path) do
    if path == Path.absname(path) do
      fun.(path)
    else
      raise "Expected an absolute path"
    end
  end

  def destroy_tmp_dir(path) do
    path |> tmp_path() |> destroy_dir()
  end
end
