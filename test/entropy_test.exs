defmodule Puid.Entropy.Test do
  use ExUnit.Case, async: true

  doctest Puid.Entropy

  import Puid.Entropy

  def i_bits(total, risk), do: round(bits(total, risk))
  def d_bits(total, risk, d), do: Float.round(bits(total, risk), d)

  test "bits" do
    assert d_bits(100, 100, 2) === 18.92
    assert d_bits(999, 1000, 2) === 28.89
    assert d_bits(1000, 1000, 2) === 28.90
    assert d_bits(10000, 1000, 2) === 35.54
    assert d_bits(1.0e4, 1.0e3, 2) === 35.54
    assert d_bits(1.0e6, 1.0e6, 2) === 58.79
    assert d_bits(1.0e6, 1.0e9, 2) === 68.76
    assert d_bits(1.0e9, 1.0e6, 2) === 78.73
    assert d_bits(1.0e9, 1.0e9, 2) === 88.69
    assert d_bits(1.0e9, 1.0e12, 2) === 98.66
    assert d_bits(1.0e9, 1.0e15, 2) === 108.62
  end

  test "preshing 32-bit" do
    assert i_bits(30084, 10) === 32
    assert i_bits(9292, 1.0e02) === 32
    assert i_bits(2932, 1.0e03) === 32
    assert i_bits(927, 1.0e04) === 32
    assert i_bits(294, 1.0e05) === 32
    assert i_bits(93, 1.0e06) === 32
    assert i_bits(30, 1.0e07) === 32
    assert i_bits(10, 1.0e08) === 32
  end

  test "preshing 64-bit" do
    assert i_bits(1.97e09, 1.0e01) === 64
    assert i_bits(6.09e08, 1.0e02) === 64
    assert i_bits(1.92e08, 1.0e03) === 64
    assert i_bits(6.07e07, 1.0e04) === 64
    assert i_bits(1.92e07, 1.0e05) === 64
    assert i_bits(6.07e06, 1.0e06) === 64
    assert i_bits(1.92e06, 1.0e07) === 64
    assert i_bits(607_401, 1.0e08) === 64
    assert i_bits(192_077, 1.0e09) === 64
    assert i_bits(60704, 1.0e10) === 64
    assert i_bits(19208, 1.0e11) === 64
    assert i_bits(6074, 1.0e12) === 64
    assert i_bits(1921, 1.0e13) === 64
    assert i_bits(608, 1.0e14) === 64
    assert i_bits(193, 1.0e15) === 64
    assert i_bits(61, 1.0e16) === 64
    assert i_bits(20, 1.0e17) === 64
    assert i_bits(7, 1.0e18) === 64
  end

  test "preshing 160-bit" do
    assert i_bits(1.42e24, 2) === 160
    assert i_bits(5.55e23, 10) === 160
    assert i_bits(1.71e23, 100) === 160
    assert i_bits(5.41e22, 1000) === 160
    assert i_bits(1.71e22, 1.0e04) === 160
    assert i_bits(5.41e21, 1.0e05) === 160
    assert i_bits(1.71e21, 1.0e06) === 160
    assert i_bits(5.41e20, 1.0e07) === 160
    assert i_bits(1.71e20, 1.0e08) === 160
    assert i_bits(5.41e19, 1.0e09) === 160
    assert i_bits(1.71e19, 1.0e10) === 160
    assert i_bits(5.41e18, 1.0e11) === 160
    assert i_bits(1.71e18, 1.0e12) === 160
    assert i_bits(5.41e17, 1.0e13) === 160
    assert i_bits(1.71e17, 1.0e14) === 160
    assert i_bits(5.41e16, 1.0e15) === 160
    assert i_bits(1.71e16, 1.0e16) === 160
    assert i_bits(5.41e15, 1.0e17) === 160
    assert i_bits(1.71e15, 1.0e18) === 160
  end

  test "entropy bits per char" do
    assert bits_per_char("0123") === {:ok, 2.0}
    assert bits_per_char("0123456789") === {:ok, 10 |> :math.log2()}

    assert bits_per_char!("0123") === 2.0
    assert bits_per_char!("0123456789") === 10 |> :math.log2()
  end

  test "entropy bits per char Error" do
    assert bits_per_char("0103") == {:error, "Invalid: chars not unique"}

    assert_raise Puid.Error, fn ->
      bits_per_char!("0103")
    end
  end
  
  test "entropy bits for string of len" do
    assert bits_for_length(14, :alphanum) === {:ok, 83}
    assert bits_for_length!(14, :alphanum) === 83

    assert bits_for_length(14, :dingosky) === {:error, "Invalid: charset not recognized"}
    assert bits_for_length(14, "dingodog") === {:error, "Invalid: chars not unique"}

    assert_raise Puid.Error, fn ->
      bits_for_length!(14, :dingosky)
    end

    assert_raise Puid.Error, fn ->
      bits_for_length!(14, "dingodog")
    end
  end

  def test_mod_len_charset(len, charset) do
    mod =
      "Puid.Entropy.Test.#{len}_#{charset |> to_string() |> String.capitalize()}"
      |> String.to_atom()

    bits = bits_for_length!(len, charset)
    defmodule(mod, do: use(Puid, bits: bits, charset: charset))
    assert mod.generate() |> String.length() === len
  end

  test "entropy bits for string using mod charset" do
    2..20
    |> Enum.each(fn len ->
      [:alpha_lower, :alpha, :alphanum, :safe32]
      |> Enum.each(fn charset ->
        test_mod_len_charset(len, charset)
      end)
    end)
  end

  def test_mod_len_chars(len, chars) do
    mod = "Puid.Entropy.Test.#{len}_#{chars |> String.length()}" |> String.to_atom()
    bits = bits_for_length!(len, chars)
    defmodule(mod, do: use(Puid, bits: bits, chars: chars))
    assert mod.generate() |> String.length() === len
  end

  test "entropy bits for string using mod chars" do
    2..20
    |> Enum.each(fn len -> test_mod_len_chars(len, "dingosky") end)
  end

  def test_mod_bits_charset(bits, charset) do
    mod =
      "Puid.Entropy.Test.#{bits}_#{charset |> to_string() |> String.capitalize()}"
      |> String.to_atom()

    len = len_for_bits!(bits, charset)
    defmodule(mod, do: use(Puid, bits: bits, charset: charset))
    assert mod.info().length === len
  end

  test "len for string of bits using charset" do
    [24, 32, 41, 50, 62, 64, 90, 101, 128]
    |> Enum.each(fn bits ->
      [:alpha_lower, :alpha, :alphanum, :safe32]
      |> Enum.each(fn charset ->
        test_mod_bits_charset(bits, charset)
      end)
    end)
  end

  def test_mod_bits_chars(bits, chars) do
    mod = "Puid.Entropy.Test.#{bits}_#{chars |> String.length()}" |> String.to_atom()

    len = len_for_bits!(bits, chars)
    defmodule(mod, do: use(Puid, bits: bits, chars: chars))
    assert mod.info().length === len
  end

  @tag :tmp
  test "len for entropy bits using mod chars" do
    [24, 32, 41, 50, 62, 64, 90, 101, 128]
    |> Enum.each(fn bits ->
      test_mod_bits_chars(bits, "dingosky")
    end)
  end
end
