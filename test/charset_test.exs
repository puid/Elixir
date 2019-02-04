defmodule Puid.CharSet.Test do
  use ExUnit.Case, async: true

  alias Puid.CharSet
  alias Puid.Entropy

  def test_charset(charset, chars) do
    assert CharSet.chars(charset) === chars
    assert Entropy.bits_per_char!(charset) === chars |> byte_size |> :math.log2()
    assert CharSet.unique?(chars)
  end

  def decimal, do: ?0..?9 |> Enum.to_list() |> to_string()
  def alpha_lower, do: ?a..?z |> Enum.to_list() |> to_string()
  def alpha_upper, do: ?A..?Z |> Enum.to_list() |> to_string()
  def alpha, do: alpha_upper() <> alpha_lower()
  def alphanum_lower, do: alpha_lower() <> decimal()
  def alphanum_upper, do: alpha_upper() <> decimal()
  def alphanum, do: alpha() <> decimal()
  def base32, do: alpha_upper() <> "234567"
  def base32_hex, do: decimal() <> (?a..?v |> Enum.to_list() |> to_string())
  def base32_hex_upper, do: decimal() <> (?A..?V |> Enum.to_list() |> to_string())
  def hex, do: decimal() <> (?a..?f |> Enum.to_list() |> to_string())
  def hex_upper, do: decimal() <> (?A..?F |> Enum.to_list() |> to_string())
  def printable_ascii, do: ?!..?~ |> Enum.to_list() |> to_string()
  def safe32, do: "2346789bdfghjmnpqrtBDFGHJLMNPQRT"
  def safe64, do: alpha_upper() <> alpha_lower() <> decimal() <> "-_"

  @tag :tmp
  test "pre-defined decimal" do
    test_charset(:decimal, decimal())
  end

  test "pre-defined lower alpha" do
    test_charset(:alpha_lower, alpha_lower())
  end

  test "pre-defined upper alpha" do
    test_charset(:alpha_upper, alpha_upper())
  end

  test "pre-defined alpha" do
    test_charset(:alpha, alpha())
  end

  test "pre-defined lower alphanum" do
    test_charset(:alphanum_lower, alphanum_lower())
  end

  test "pre-defined upper alphanum" do
    test_charset(:alphanum_upper, alphanum_upper())
  end

  test "pre-defined alphanum" do
    test_charset(:alphanum, alphanum())
  end

  test "pre-defined base32" do
    test_charset(:base32, base32())
  end

  test "pre-defined base32 hex" do
    test_charset(:base32_hex, base32_hex())
  end

  test "pre-defined base32 upper hex" do
    test_charset(:base32_hex_upper, base32_hex_upper())
  end

  test "pre-defined hex" do
    test_charset(:hex, hex())
  end

  test "pre-defined upper hex" do
    test_charset(:hex_upper, hex_upper())
  end

  test "pre-defined safe32" do
    test_charset(:safe32, safe32())
  end

  test "pre-defined safe64" do
    test_charset(:safe64, safe64())
  end

  test "pre-defined printable ascii" do
    test_charset(:printable_ascii, printable_ascii())
  end

end
