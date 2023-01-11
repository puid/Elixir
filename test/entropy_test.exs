# MIT License
#
# Copyright (c) 2019-2023 Knoxen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
defmodule Puid.Test.Entropy do
  use ExUnit.Case, async: true

  doctest Puid.Entropy

  import Puid.Entropy

  defp i_bits(total, risk), do: round(bits(total, risk))
  defp d_bits(total, risk, d), do: Float.round(bits(total, risk), d)

  defp assert_error_matches({:error, reason}, snippet),
    do: assert(reason |> String.contains?(snippet))

  test "bits" do
    assert bits(0, 1.0e12) === 0
    assert bits(1, 1.0e12) === 0

    assert bits(500, 0) === 0
    assert bits(500, 1) === 0

    assert bits(10_500, 0) === 0
    assert bits(10_500, 1) === 0

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

  #
  # bits_per_char
  #
  test "valid bits_per_char" do
    assert bits_per_char(:hex) === {:ok, 4.0}
    {:ok, ebpc} = bits_per_char(:alphanum)
    assert ebpc |> Float.round(2) == 5.95

    assert bits_per_char('dingosky') === {:ok, 3.0}
    assert bits_per_char('0123456789') === {:ok, 10 |> :math.log2()}

    assert bits_per_char("0123") === {:ok, 2.0}
    assert bits_per_char("0123456789ok") === {:ok, 12 |> :math.log2()}
  end

  test "valid bits_per_char!" do
    assert bits_per_char!(:hex) === 4.0
    assert bits_per_char!(:alphanum) |> Float.round(2) == 5.95

    assert bits_per_char!('dingosky') === 3.0
    assert bits_per_char!('0123456789') === 10 |> :math.log2()

    assert bits_per_char!("0123") === 2.0
    assert bits_per_char!("0123456789ok") === 12 |> :math.log2()
  end

  test "invalid pre-defined bits_per_char" do
    :invalid |> bits_per_char() |> assert_error_matches("pre-defined")

    assert_raise Puid.Error, fn -> bits_per_char!(:invalid) end
  end

  test "non-unique bits_per_char" do
    'unique' |> bits_per_char() |> assert_error_matches("unique")
    assert_raise Puid.Error, fn -> bits_per_char!('unique') end
  end

  test "too short bits_per_char" do
    'u' |> bits_per_char() |> assert_error_matches("least 2")
    "" |> bits_per_char() |> assert_error_matches("least 2")

    assert_raise Puid.Error, fn -> bits_per_char!('') end
    assert_raise Puid.Error, fn -> bits_per_char!("u") end
  end

  test "too long bits_per_char" do
    ascii = Puid.Chars.charlist!(:safe_ascii)
    too_long = ascii ++ ascii ++ ascii

    too_long |> bits_per_char() |> assert_error_matches("count")

    assert_raise Puid.Error, fn -> bits_per_char!(too_long) end
  end

  #
  # bits_for_len
  #
  test "valid bits_for_len" do
    assert :alphanum |> bits_for_len(14) === {:ok, 83}
    assert 'dingosky' |> bits_for_len(14) === {:ok, 42}
    assert "uncopyrightable" |> bits_for_len(14) === {:ok, 54}
  end

  test "valid bits_for_len!" do
    assert :alphanum |> bits_for_len!(14) === 83
    assert 'uncopyrightable' |> bits_for_len!(14) === 54
    assert "dingosky" |> bits_for_len!(14) === 42
  end

  test "invalid pre-defined bits_for_len" do
    :invalid |> bits_for_len(10) |> assert_error_matches("pre-defined")

    assert_raise Puid.Error, fn -> :invalid |> bits_for_len!(20) end
  end

  test "non-unique bits_for_len" do
    'unique' |> bits_for_len(14) |> assert_error_matches("unique")

    assert_raise Puid.Error, fn -> 'unique' |> bits_for_len!(20) end
  end

  test "too short bits_for_len" do
    'u' |> bits_for_len(10) |> assert_error_matches("least 2")
    "" |> bits_for_len(20) |> assert_error_matches("least 2")

    assert_raise Puid.Error, fn -> 'u' |> bits_for_len!(10) end
  end

  test "too long bits_for_len" do
    ascii = Puid.Chars.charlist!(:safe_ascii)
    too_long = ascii ++ ascii ++ ascii

    too_long |> bits_for_len(10) |> assert_error_matches("count")
    assert_raise Puid.Error, fn -> too_long |> bits_for_len!(10) end
  end

  #
  # len_for_bits
  #
  test "valid len_for_bits" do
    assert :alphanum |> len_for_bits(83) === {:ok, 14}
    assert 'dingosky' |> len_for_bits(42) === {:ok, 14}
    assert "uncopyrightable" |> len_for_bits(54) === {:ok, 14}
  end

  test "valid len_for_bits!" do
    assert :alphanum |> len_for_bits!(83) === 14
    assert 'uncopyrightable' |> len_for_bits!(54) === 14
    assert "dingosky" |> len_for_bits!(42) === 14
  end

  test "invalid pre-defined len_for_bits" do
    :invalid |> len_for_bits(10) |> assert_error_matches("pre-defined")

    assert_raise Puid.Error, fn -> :invalid |> len_for_bits!(20) end
  end

  test "non-unique len_for_bits" do
    'unique' |> len_for_bits(14) |> assert_error_matches("unique")
    assert_raise Puid.Error, fn -> 'unique' |> len_for_bits!(20) end
  end

  test "too short len_for_bits" do
    'u' |> len_for_bits(10) |> assert_error_matches("least 2")
    "" |> len_for_bits(20) |> assert_error_matches("least 2")
    assert_raise Puid.Error, fn -> 'u' |> len_for_bits!(10) end
  end

  test "too long len_for_bits" do
    ascii = Puid.Chars.charlist!(:safe_ascii)
    too_long = ascii ++ ascii ++ ascii

    too_long |> len_for_bits(10) |> assert_error_matches("count")
    assert_raise Puid.Error, fn -> too_long |> len_for_bits!(10) end
  end
end
