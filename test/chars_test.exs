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
defmodule Puid.Test.Chars do
  use ExUnit.Case, async: true

  doctest Puid.Chars

  alias Puid.Chars

  def predefined_chars,
    do: [
      :alpha,
      :alpha_lower,
      :alpha_upper,
      :alphanum,
      :alphanum_lower,
      :alphanum_upper,
      :base16,
      :base32,
      :base32_hex,
      :base32_hex_upper,
      :base58,
      :crockford32,
      :decimal,
      :hex,
      :hex_upper,
      :safe_ascii,
      :safe32,
      :safe64,
      :symbol,
      :wordSafe32
    ]

  test "charlist of pre-defined chars" do
    predefined_chars()
    |> Enum.each(fn predefined ->
      {:ok, charlist} = Chars.charlist(predefined)
      assert is_list(charlist)
    end)

    predefined_chars()
    |> Enum.each(fn predefined ->
      charlist = Chars.charlist!(predefined)
      assert is_list(charlist)
    end)
  end

  test "charlist of ascii charlist" do
    {:ok, charlist} = Chars.charlist(~c"dingosky")
    assert is_list(charlist)

    assert(~c"dingosky" |> Chars.charlist!() |> is_list())
  end

  test "charlist of ascii String" do
    {:ok, charlist} = Chars.charlist("dingosky")
    assert is_list(charlist)

    assert("dingosky" |> Chars.charlist!() |> is_list())
  end

  test "charlist of unicode charlist" do
    {:ok, charlist} = Chars.charlist(~c"dîngøsky")
    assert is_list(charlist)

    assert(~c"dîngøsky" |> Chars.charlist!() |> is_list())
  end

  test "charlist of unicode String" do
    {:ok, charlist} = Chars.charlist("dîngøsky")
    assert is_list(charlist)

    assert("dîngøsky" |> Chars.charlist!() |> is_list())
  end

  test "charlist of unknown pre-defined chars" do
    assert {:error, reason} = Chars.charlist(:unknown)
    assert reason |> String.contains?("pre-defined")

    assert_raise(Puid.Error, fn -> Chars.charlist!(:unknown) end)
  end

  test "charlist of non-unique String" do
    assert {:error, reason} = Chars.charlist("unique")
    assert reason |> String.contains?("not unique")

    assert_raise(Puid.Error, fn -> Chars.charlist!(~c"unique") end)
  end

  test "charlist of too short String" do
    assert {:error, reason} = Chars.charlist("0")
    assert reason |> String.contains?("least")

    assert_raise(Puid.Error, fn -> Chars.charlist!("") end)
  end

  test "charlist with too many chars" do
    too_long = 229..500 |> Enum.map(& &1) |> to_string()
    assert {:error, reason} = too_long |> Chars.charlist()
    assert reason |> String.contains?("count")

    assert_raise(Puid.Error, fn -> Chars.charlist!(too_long) end)
  end

  test "invalid charlist error" do
    assert {:error, reason} = Chars.charlist("dingo sky")
    assert reason |> String.contains?("Invalid")
  end

  test "charlist with unsafe ascii" do
    assert_raise(Puid.Error, fn -> Chars.charlist!(~c"dingo sky") end)
    assert_raise(Puid.Error, fn -> Chars.charlist!(~c"dingo\"sky") end)
    assert_raise(Puid.Error, fn -> Chars.charlist!(~c"dingo'sky") end)
    assert_raise(Puid.Error, fn -> Chars.charlist!(~c"dingo\\sky") end)
    assert_raise(Puid.Error, fn -> Chars.charlist!(~c"dingo`sky") end)
  end

  test "String with unsafe ascii" do
    assert_raise(Puid.Error, fn -> Chars.charlist!("dingo`sky") end)
  end

  test "charlist with unsafe utf8 between tilde and inverse bang" do
    assert_raise(Puid.Error, fn -> Chars.charlist!("dingo\u00A0sky") end)
  end

  test "ascii encoding" do
    assert Chars.encoding("abc") == :ascii
    assert Chars.encoding("abc∂ef") == :utf8
  end

  test "invalid encoding" do
    assert_raise(Puid.Error, fn -> Chars.encoding(~c"ab cd") end)
  end

  describe "metrics/1" do
    test "power-of-2 charsets have perfect ETE" do
      power_of_2_charsets = [
        :base16,
        :base32,
        :base32_hex,
        :base32_hex_upper,
        :crockford32,
        :hex,
        :hex_upper,
        :safe32,
        :safe64,
        :wordSafe32
      ]

      Enum.each(power_of_2_charsets, fn charset ->
        metric = Chars.metrics(charset)

        assert metric.ete == 1.0,
               "#{charset} should have ETE = 1.0, got #{metric.ete}"
      end)
    end

    test "known ETE values for non-power-of-2 charsets" do
      test_cases = [
        {:alphanum_lower, 0.65, 0.01},
        {:alphanum, 0.97, 0.01},
        {:decimal, 0.62, 0.01},
        {:alpha_lower, 0.81, 0.01},
        {:alpha_upper, 0.81, 0.01},
        {:alphanum_upper, 0.65, 0.01},
        {:alpha, 0.84, 0.01},
        {:base58, 0.91, 0.01}
      ]

      Enum.each(test_cases, fn {charset, expected_ete, tolerance} ->
        metric = Chars.metrics(charset)

        assert abs(metric.ete - expected_ete) < tolerance,
               "#{charset} should have ETE ≈ #{expected_ete}, got #{Float.round(metric.ete, 4)}"
      end)
    end

    test "ETE is always between 0 and 1" do
      all_charsets = predefined_chars()

      Enum.each(all_charsets, fn charset ->
        metric = Chars.metrics(charset)

        assert metric.ete > 0 and metric.ete <= 1.0,
               "#{charset} has invalid ETE: #{metric.ete}"
      end)
    end

    test "ETE result structure" do
      metric = Chars.metrics(:alphanum_lower)

      assert is_map(metric)
      assert Map.has_key?(metric, :avg_bits)
      assert Map.has_key?(metric, :bit_shifts)
      assert Map.has_key?(metric, :ere)
      assert Map.has_key?(metric, :ete)

      assert is_float(metric.avg_bits)
      assert is_list(metric.bit_shifts)
      assert is_float(metric.ere)
      assert is_float(metric.ete)

      # Verify all expected keys are present
      expected_keys = [:avg_bits, :bit_shifts, :ere, :ete]
      assert Map.keys(metric) |> Enum.sort() == expected_keys
    end

    test "custom charset ETE" do
      custom_36 = "abcdefghijklmnopqrstuvwxyz0123456789"
      metric = Chars.metrics(custom_36)

      alphanum_lower_metric = Chars.metrics(:alphanum_lower)
      assert abs(metric.ete - alphanum_lower_metric.ete) < 0.0001
    end
  end
end
