defmodule PhoenixOauth2Provider.Test.MixHelpers do
  @moduledoc false

  import ExUnit.Assertions

  @spec tmp_path :: binary()
  def tmp_path do
    Path.expand("../../tmp", __DIR__)
  end

  @spec in_tmp(Path.t(), (-> Path.res())) :: Path.res() | no_return
  def in_tmp(which, function) do
    path = Path.join(tmp_path(), which)

    File.rm_rf!(path)
    File.mkdir_p!(path)
    File.cd!(path, function)
  end

  def assert_file(file) do
    assert File.regular?(file), "Expected #{file} to exist, but does not"
  end

  def refute_file(file) do
    refute File.regular?(file), "Expected #{file} to not exist, but it does"
  end

  def assert_file(file, match) do
    cond do
      is_list(match) ->
        assert_file file, &(Enum.each(match, fn(m) -> assert &1 =~ m end))
      is_binary(match) or Regex.regex?(match) ->
        assert_file file, &(assert &1 =~ match)
      is_function(match, 1) ->
        assert_file(file)
        match.(File.read!(file))
    end
  end

  def assert_dirs(dirs, full_dirs, path) do
    Enum.each dirs, fn dir ->
      assert File.dir?(Path.join(path, dir))
    end

    Enum.each full_dirs -- dirs, fn dir ->
      refute File.dir?(Path.join(path, dir))
    end
  end

  def assert_file_list(files, full_files, path) do
    Enum.each files, fn file ->
      assert_file Path.join(path, file)
    end

    Enum.each full_files -- files, fn file ->
      refute_file Path.join(path, file)
    end
  end
end
