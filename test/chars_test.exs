# MIT License
#
# Copyright (c) 2019-2022 Knoxen
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

  alias Puid.Chars

  def predefined_chars,
    do: [
      :alpha,
      :alpha_lower,
      :alpha_upper,
      :alphanum,
      :alphanum_lower,
      :alphanum_upper,
      :base32,
      :base32_hex,
      :base32_hex_upper,
      :decimal,
      :hex,
      :hex_upper,
      :safe_ascii,
      :safe32,
      :safe64,
      :symbol
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
    {:ok, charlist} = Chars.charlist('dingosky')
    assert is_list(charlist)

    assert('dingosky' |> Chars.charlist!() |> is_list())
  end

  test "charlist of ascii String" do
    {:ok, charlist} = Chars.charlist("dingosky")
    assert is_list(charlist)

    assert("dingosky" |> Chars.charlist!() |> is_list())
  end

  test "charlist of unicode charlist" do
    {:ok, charlist} = Chars.charlist('dîngøsky')
    assert is_list(charlist)

    assert('dîngøsky' |> Chars.charlist!() |> is_list())
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

    assert_raise(Puid.Error, fn -> Chars.charlist!('unique') end)
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

  test "ascii encoding" do
    assert Chars.encoding("abc") == :ascii
    assert Chars.encoding("abc∂ef") == :utf8
  end

  test "invalid encoding" do
    assert_raise(Puid.Error, fn -> Chars.encoding("ab cd") end)
    assert_raise(Puid.Error, fn -> Chars.encoding([?~, 127]) end)
  end
end
