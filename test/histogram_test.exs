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
defmodule Puid.Test.Histogram do
  use ExUnit.Case

  @tag :histogram
  @tag :hex
  test ":hex", do: test_chars("Hex", "HistHexId", :hex)

  @tag :histogram
  @tag :safe32
  test ":safe32", do: test_chars("Safe32", "HistSafe32Id", :safe32)

  @tag :histogram
  @tag :alpha_lower
  test ":alpha_lower", do: test_chars("AlphaLower", "HistAlphaLowerId", :alpha_lower)

  @tag :histogram
  @tag :alphanum
  test ":alphanum", do: test_chars("Alphanumeric", "HistAlphanumId", :alphanum)

  @tag :histogram
  @tag :safe_ascii
  test ":safe_ascii", do: test_chars("All ASCII", "HistSafeAsciiId", :safe_ascii)

  @tag :histogram
  @tag :custom_8
  test "ascii", do: test_chars("8 custom ASCII", "HistDingoSkyId", "dingosky")

  @tag :histogram
  @tag :alpha_9_lower
  test "alpha 9 lower", do: test_chars("9 alpha lower chars", "HistAlpha9LowerId", "abcdefghi")

  @tag :histogram
  @tag :alpha_10_lower
  test "alpha 10 lower",
    do: test_chars("10 alpha lower chars", "HistAlpha10LowerId", "abcdefghij")

  @tag :histogram
  @tag :unicode
  test "unicode",
    do: test_chars("Unicode characters", "HistDingoSkyUnicodeId", "dîñgø$kyDÎÑGØßK¥")

  defp test_chars(descr, id_name, chars) do
    trials = 500_000
    risk = 1.0e12
    mod_name = String.to_atom(id_name)

    IO.write("#{descr} ... ")

    defmodule(mod_name, do: use(Puid, chars: chars, total: trials, risk: risk))

    {passed, expect, histogram} = chi_square_test(mod_name, trials)

    if passed,
      do: IO.puts("ok"),
      else: IO.inspect(histogram, label: "\nFailed histogram for #{id_name}, expected #{expect}")

    assert passed
  end

  def chi_square_test(puid_mod, trials, n_sigma \\ 4) do
    init_histogram =
      puid_mod.info().characters
      |> to_charlist()
      |> Enum.reduce(%{}, &Map.put(&2, &1, 0))

    chars_len = String.length(puid_mod.info().characters)

    histogram =
      1..trials
      |> Enum.reduce(init_histogram, fn _, acc_histogram ->
        puid_mod.generate()
        |> to_charlist()
        |> Enum.reduce(acc_histogram, &Map.put(&2, &1, &2[&1] + 1))
      end)

    expect = trials * puid_mod.info().length / chars_len

    chi_square =
      histogram
      |> Enum.reduce(0, fn {_, value}, acc ->
        diff = value - expect
        acc + diff * diff / expect
      end)

    deg_freedom = chars_len - 1
    variance = :math.sqrt(2 * deg_freedom)
    tolerance = n_sigma * variance

    passed = chi_square < deg_freedom + tolerance and chi_square > deg_freedom - tolerance

    {passed, round(expect), histogram}
  end
end
