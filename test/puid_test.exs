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
defmodule Puid.Test do
  use ExUnit.Case, async: true

  alias Puid.Chars
  alias Puid.Entropy

  defp test_char_set(char_set, length, bits \\ 128) do
    mod = String.to_atom("#{char_set}_#{bits}_Id")
    defmodule(mod, do: use(Puid, chars: char_set, bits: bits))

    epbc = Entropy.bits_per_char!(char_set)
    eb = length * epbc
    ere = epbc / 8.0
    round_to = 2

    assert mod.info.char_set === char_set
    assert mod.info.length === length

    assert mod.info.entropy_bits_per_char === Float.round(epbc, round_to)
    assert mod.info.entropy_bits === Float.round(eb, round_to)
    assert mod.info.ere === Float.round(ere, round_to)
    assert mod.generate |> String.length() === length
  end

  test "pre-defined safe ascii chars" do
    test_char_set(:safe_ascii, 20)
    test_char_set(:safe_ascii, 10, 64)
    test_char_set(:safe_ascii, 40, 256)
  end

  test "pre-defined alpha chars" do
    test_char_set(:alpha, 23)
    test_char_set(:alpha, 12, 64)
    test_char_set(:alpha, 45, 256)
  end

  test "pre-defined lower alpha chars" do
    test_char_set(:alpha_lower, 28)
    test_char_set(:alpha_lower, 14, 64)
    test_char_set(:alpha_lower, 55, 256)
  end

  test "pre-defined upper alpha chars" do
    test_char_set(:alpha_upper, 28)
    test_char_set(:alpha_upper, 14, 64)
    test_char_set(:alpha_upper, 55, 256)
  end

  test "pre-defined alphanum" do
    test_char_set(:alphanum, 22)
    test_char_set(:alphanum, 11, 64)
    test_char_set(:alphanum, 43, 256)
  end

  test "pre-defined lower alphanum" do
    test_char_set(:alphanum_lower, 25)
    test_char_set(:alphanum_lower, 13, 64)
    test_char_set(:alphanum_lower, 50, 256)
  end

  test "pre-defined upper alphanum" do
    test_char_set(:alphanum_upper, 25)
    test_char_set(:alphanum_upper, 13, 64)
    test_char_set(:alphanum_upper, 50, 256)
  end

  test "pre-defined hex" do
    test_char_set(:hex, 32)
    test_char_set(:hex, 16, 64)
    test_char_set(:hex, 64, 256)
  end

  test "pre-defined upper hex" do
    test_char_set(:hex_upper, 32)
    test_char_set(:hex_upper, 16, 64)
    test_char_set(:hex_upper, 64, 256)
  end

  test "pre-defined base32" do
    test_char_set(:base32, 26)
    test_char_set(:base32, 13, 64)
    test_char_set(:base32, 52, 256)
  end

  test "pre-defined base32 hex" do
    test_char_set(:base32_hex, 26)
    test_char_set(:base32_hex, 13, 64)
    test_char_set(:base32_hex, 52, 256)
  end

  test "pre-defined base32 upper hex" do
    test_char_set(:base32_hex_upper, 26)
    test_char_set(:base32_hex_upper, 13, 64)
    test_char_set(:base32_hex_upper, 52, 256)
  end

  test "pre-defined safe32" do
    test_char_set(:safe32, 26)
    test_char_set(:safe32, 13, 64)
    test_char_set(:safe32, 52, 256)
  end

  test "pre-defined safe64" do
    test_char_set(:safe64, 22)
    test_char_set(:safe64, 11, 64)
    test_char_set(:safe64, 43, 256)
  end

  defp test_characters(chars) do
    puid_mod =
      "#{chars |> to_string() |> String.capitalize()}Puid"
      |> String.to_atom()

    defmodule(puid_mod, do: use(Puid, chars: chars))

    characters = puid_mod.info().characters

    1..100
    |> Enum.each(fn _ ->
      puid_mod.generate()
      |> String.graphemes()
      |> Enum.each(fn symbol -> characters |> String.contains?(symbol) end)
    end)
  end

  test "pre-defined chars mod chars" do
    [
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
      :safe64
    ]
    |> Enum.each(&test_characters(&1))
  end

  test "default puid" do
    defmodule(DefaultId, do: use(Puid))
    assert DefaultId.info().characters === Chars.charlist!(:safe64) |> to_string()
    assert DefaultId.info().char_set === :safe64
    assert DefaultId.info().length === 22
    assert DefaultId.info().entropy_bits_per_char === 6.0
    assert DefaultId.info().entropy_bits === 132.0
    assert DefaultId.info().rand_bytes === (&:crypto.strong_rand_bytes/1)
    assert DefaultId.info().ere === 0.75
    assert byte_size(DefaultId.generate()) === DefaultId.info().length
  end

  test "total/risk" do
    defmodule(TotalRiskId, do: use(Puid, total: 10_000, risk: 1.0e12, chars: :alpha))

    info = TotalRiskId.info()
    assert info.entropy_bits === 68.41
    assert info.entropy_bits_per_char == 5.7
    assert info.ere == 0.71
    assert info.length == 12
  end

  test "invalid chars" do
    assert_raise Puid.Error, fn ->
      defmodule(NoNoId, do: use(Puid, chars: 'unique'))
    end

    assert_raise Puid.Error, fn ->
      defmodule(NoNoId, do: use(Puid, chars: "u"))
    end

    assert_raise Puid.Error, fn ->
      defmodule(NoNoId, do: use(Puid, chars: 'dingo\n'))
    end
  end

  defp test_predefined_chars_mod(descr, chars, bits, rand_bytes_mod, expect) do
    puid_mod = String.to_atom("#{descr}_#{bits}_bits")

    defmodule(puid_mod,
      do: use(Puid, bits: bits, chars: chars, rand_bytes: &rand_bytes_mod.rand_bytes/1)
    )

    test_mod(puid_mod, expect, rand_bytes_mod)
  end

  defp test_custom_chars_mod(descr, chars, bits, rand_bytes_mod, expect) do
    puid_mod = String.to_atom("#{descr}_#{bits}_bits")

    defmodule(puid_mod,
      do: use(Puid, bits: bits, chars: chars, rand_bytes: &rand_bytes_mod.rand_bytes/1)
    )

    test_mod(puid_mod, expect, rand_bytes_mod)
  end

  defp test_mod(puid_mod, expect, rand_bytes_mod) do
    assert puid_mod.generate() === expect

    bits_mod =
      ("Elixir." <> (puid_mod |> to_string()) <> ".Bits")
      |> String.to_atom()

    rand_bytes_mod.reset()
    bits_mod.reset()
  end

  test "26 lower alpha chars (5 bits)" do
    defmodule(LowerAlphaBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xF1, 0xB1, 0x78, 0x0A, 0xCE>>)
    )

    bits_expect = &test_predefined_chars_mod("LowerAlpha", :alpha_lower, &1, LowerAlphaBytes, &2)

    # shifts: [{26, 5}, {31, 3}]
    #
    #    F    1    B    1    7    8    0    A    C    E
    # 1111 0001 1011 0001 0111 1000 0000 1010 1100 1110
    #
    # 111 10001 10110 00101 111 00000 00101 01100 1110
    # xxx |---| |---| |---| xxx |---| |---| |---|
    #  30   17    22     5   30    0     5    12   14
    #        r     w     f         a     f     m
    #
    bits_expect.(4, "r")
    bits_expect.(5, "rw")
    bits_expect.(10, "rwf")
    bits_expect.(14, "rwf")
    bits_expect.(15, "rwfa")
    bits_expect.(18, "rwfa")
    bits_expect.(19, "rwfaf")
    bits_expect.(24, "rwfafm")
  end

  test "lower alpha carry (26 chars, 5 bits)" do
    defmodule(LowerAlphaCarryBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xF1, 0xB1, 0x78, 0x0A, 0xCE>>)
    )

    defmodule(PuidWithAgent,
      do:
        use(Puid,
          bits: 5,
          chars: :alpha_lower,
          rand_bytes: &LowerAlphaCarryBytes.rand_bytes/1
        )
    )

    assert PuidWithAgent.generate() === "rw"
    assert PuidWithAgent.generate() === "fa"
    assert PuidWithAgent.generate() === "fm"
  end

  test "hex chars, variable bits" do
    defmodule(FixedHexBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A>>)
    )

    bits_expect = &test_predefined_chars_mod("Hex", :hex, &1, FixedHexBytes, &2)

    bits_expect.(3, "c")
    bits_expect.(4, "c")
    bits_expect.(5, "c7")
    bits_expect.(8, "c7")
    bits_expect.(9, "c7c")
    bits_expect.(12, "c7c")
    bits_expect.(15, "c7c9")
    bits_expect.(16, "c7c9")
    bits_expect.(19, "c7c90")
    bits_expect.(20, "c7c90")
    bits_expect.(23, "c7c900")
    bits_expect.(24, "c7c900")
    bits_expect.(27, "c7c9002")
    bits_expect.(28, "c7c9002")
    bits_expect.(31, "c7c9002a")
    bits_expect.(32, "c7c9002a")
  end

  @tag :only
  test "safe32 chars (5 bits)" do
    defmodule(Safe32Bytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C>>)
    )

    #    D    2    E    3    E    9    D    A    1    9    0    3    B    7    3    C
    # 1101 0010 1110 0011 1110 1001 1101 1010 0001 1001 0000 0011 1011 0111 0011 1100
    #
    # 11010 01011 10001 11110 10011 10110 10000 11001 00000 01110 11011 10011 1100
    # |---| |---| |---| |---| |---| |---| |---| |---| |---| |---| |---| |---|
    #  26    11    17    30    19    22    16    25     0    14    27    19
    #   M     h     r     R     B     G     q     L     2     n     N     B

    bits_expect = &test_predefined_chars_mod("Safe32", :safe32, &1, Safe32Bytes, &2)

    bits_expect.(4, "M")
    bits_expect.(5, "M")
    bits_expect.(6, "Mh")
    bits_expect.(10, "Mh")
    bits_expect.(11, "Mhr")
    bits_expect.(15, "Mhr")
    bits_expect.(16, "MhrR")
    bits_expect.(20, "MhrR")
    bits_expect.(21, "MhrRB")
    bits_expect.(25, "MhrRB")
    bits_expect.(26, "MhrRBG")
    bits_expect.(30, "MhrRBG")
    bits_expect.(31, "MhrRBGq")
    bits_expect.(35, "MhrRBGq")
    bits_expect.(36, "MhrRBGqL")
    bits_expect.(40, "MhrRBGqL")
    bits_expect.(41, "MhrRBGqL2")
    bits_expect.(45, "MhrRBGqL2")
    bits_expect.(46, "MhrRBGqL2n")
    bits_expect.(50, "MhrRBGqL2n")
    bits_expect.(52, "MhrRBGqL2nN")
    bits_expect.(58, "MhrRBGqL2nNB")
  end

  test "base32 chars (5 bits)" do
    defmodule(Base32Bytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x00, 0x22>>)
    )

    bits_expect = &test_predefined_chars_mod("Base32", :base32, &1, Base32Bytes, &2)

    bits_expect.(41, "2LR6TWQZA")
    bits_expect.(45, "2LR6TWQZA")
    bits_expect.(46, "2LR6TWQZAA")
  end

  test "safe64 chars (6 bits)" do
    defmodule(Safe64Bytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00>>)
    )

    bits_expect = &test_predefined_chars_mod("Safe64", :safe64, &1, Safe64Bytes, &2)

    bits_expect.(24, "0uPp")
    bits_expect.(25, "0uPp-")
    bits_expect.(42, "0uPp-hk")
    bits_expect.(47, "0uPp-hkA")
    bits_expect.(48, "0uPp-hkA")
  end

  test "hex chars without carry" do
    defmodule(HexNoCarryBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD>>)
    )

    #    C    7    C    9    0    0    2    A    B    D
    # 1100 0111 1100 1001 0000 0000 0010 1010 1011 1100

    defmodule(HexNoCarryId,
      do: use(Puid, bits: 16, chars: :hex_upper, rand_bytes: &HexNoCarryBytes.rand_bytes/1)
    )

    assert HexNoCarryId.generate() == "C7C9"
    assert HexNoCarryId.generate() == "002A"
  end

  test "hex chars with carry" do
    defmodule(HexCarryBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD>>)
    )

    #    C    7    C    9    0    0    2    A    B    D
    # 1100 0111 1100 1001 0000 0000 0010 1010 1011 1100

    defmodule(HexCarryId,
      do: use(Puid, bits: 12, chars: :hex_upper, rand_bytes: &HexCarryBytes.rand_bytes/1)
    )

    assert HexCarryId.generate() == "C7C"
    assert HexCarryId.generate() == "900"
    assert HexCarryId.generate() == "2AB"
  end

  test "dingosky chars without carry" do
    defmodule(DingoSkyNoCarryBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD, 0x72>>)
    )

    #    C    7    C    9    0    0    2    A    B    D    7    2
    # 1100 0111 1100 1001 0000 0000 0010 1010 1011 1101 0111 0010
    #
    # 110 001 111 100 100 100 000 000 001 010 101 011 110 101 110 010
    # |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-|
    #  k   i   y   o   o   o   d   d   i   n   s   g   k   s   k   n

    defmodule(DingoSkyNoCarryId,
      do: use(Puid, bits: 24, chars: 'dingosky', rand_bytes: &DingoSkyNoCarryBytes.rand_bytes/1)
    )

    assert DingoSkyNoCarryId.generate() == "kiyooodd"
    assert DingoSkyNoCarryId.generate() == "insgkskn"
  end

  test "TF chars without carry" do
    defmodule(TFNoCarryBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0b11111011, 0b00000100, 0b00101100, 0b10110011>>)
    )

    defmodule(TFNoCarryId,
      do: use(Puid, bits: 16, chars: 'FT', rand_bytes: &TFNoCarryBytes.rand_bytes/1)
    )

    assert TFNoCarryId.generate() == "TTTTTFTTFFFFFTFF"
    assert TFNoCarryId.generate() == "FFTFTTFFTFTTFFTT"
  end

  test "dingosky chars with carry" do
    defmodule(DingoSkyCarryBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD, 0x72>>)
    )

    #    C    7    C    9    0    0    2    A    B    D    7    2
    # 1100 0111 1100 1001 0000 0000 0010 1010 1011 1101 0111 0010
    #
    # 110 001 111 100 100 100 000 000 001 010 101 011 110 101 110 010
    # |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-|
    #  k   i   y   o   o   o   d   d   i   n   s   g   k   s   k   n

    defmodule(DingoSkyCarryId,
      do: use(Puid, bits: 9, chars: 'dingosky', rand_bytes: &DingoSkyCarryBytes.rand_bytes/1)
    )

    assert DingoSkyCarryId.generate() == "kiy"
    assert DingoSkyCarryId.generate() == "ooo"
    assert DingoSkyCarryId.generate() == "ddi"
    assert DingoSkyCarryId.generate() == "nsg"
    assert DingoSkyCarryId.generate() == "ksk"
  end

  test "dîngøsky chars with carry" do
    defmodule(DingoSkyUtf8Bytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD, 0x72>>)
    )

    #    C    7    C    9    0    0    2    A    B    D    7    2
    # 1100 0111 1100 1001 0000 0000 0010 1010 1011 1101 0111 0010
    #
    # 110 001 111 100 100 100 000 000 001 010 101 011 110 101 110 010
    # |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-|
    #  k   î   y   ø   ø   ø   d   d   î   n   s   g   k   s   k   n

    defmodule(DingoskyUtf8CarryId,
      do: use(Puid, bits: 9, chars: 'dîngøsky', rand_bytes: &DingoSkyUtf8Bytes.rand_bytes/1)
    )

    assert DingoskyUtf8CarryId.generate() == "kîy"
    assert DingoskyUtf8CarryId.generate() == "øøø"
    assert DingoskyUtf8CarryId.generate() == "ddî"
    assert DingoskyUtf8CarryId.generate() == "nsg"
    assert DingoskyUtf8CarryId.generate() == "ksk"
  end

  test "safe32 with carry" do
    defmodule(Safe32NoCarryBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C>>)
    )

    #    D    2    E    3    E    9    D    A    1    9    0    3    B    7    3    C
    # 1101 0010 1110 0011 1110 1001 1101 1010 0001 1001 0000 0011 1011 0111 0011 1100
    #
    # 11010 01011 10001 11110 10011 10110 10000 11001 00000 01110 11011 10011 1100
    # |---| |---| |---| |---| |---| |---| |---| |---| |---| |---| |---| |---|
    #  26    11    17    30    19    22    16    25     0    14    27    19
    #   M     h     r     R     B     G     q     L     2     n     N     B

    defmodule(Safe32CarryId,
      do: use(Puid, bits: 20, chars: :safe32, rand_bytes: &Safe32NoCarryBytes.rand_bytes/1)
    )

    assert Safe32CarryId.generate() == "MhrR"
    assert Safe32CarryId.generate() == "BGqL"
    assert Safe32CarryId.generate() == "2nNB"
  end

  test "62 alphanum chars (6 bits)" do
    defmodule(AlphaNumBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00>>)
    )

    bits_expect = &test_predefined_chars_mod("AlphaNum", :alphanum, &1, AlphaNumBytes, &2)

    # shifts: [{62, 6}]
    #
    #    D    2    E    3    E    9    F    A    1    9    0    0
    # 1101 0010 1110 0011 1110 1001 1111 1010 0001 1001 0000 0000
    #
    # 110100 101110 001111 101001 111110 100001 100100 000000
    # |----| |----| |----| |----| xxxxxx |----| |----| |----|
    #   52     46     15     41     62     33     36      0
    #    0      u      P      p             h      k      A
    #
    bits_expect.(41, "0uPphkA")
  end

  test "alphanum chars (62 chars, 6 bits) carry" do
    defmodule(AlphaNumCarryBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00>>)
    )

    defmodule(AlphaNumCarryId,
      do: use(Puid, bits: 12, chars: :alphanum, rand_bytes: &AlphaNumCarryBytes.rand_bytes/1)
    )

    #
    #    D    2    E    3    E    9    F    A    1    9    0    0
    # 1101 0010 1110 0011 1110 1001 1111 1010 0001 1001 0000 0000
    #
    # 110100 101110 001111 101001 111110 100001 100100 000000
    # |----| |----| |----| |----| xxxxxx |----| |----| |----|
    #   52     46     15     41     62     33     36      0
    #    0      u      P      p             h      k      A
    #
    assert AlphaNumCarryId.generate() == "0uP"
    assert AlphaNumCarryId.generate() == "phk"
  end

  test "10 vowels chars (4 bits)" do
    defmodule(VowelBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xA6, 0x33, 0xF6, 0x9E, 0xBD, 0xEE, 0xA7>>)
    )

    bits_expect = &test_custom_chars_mod("Vowels", "aeiouAEIOU", &1, VowelBytes, &2)

    # shifts: [{10, 4}, {15, 2}]
    #
    #    A    6    3    3    F    6    9    E    B    D    E    E    A    7
    # 1010 0110 0011 0011 1111 0110 1001 1110 1011 1101 1110 1110 1010 0111
    #
    # 1010 0110 0011 0011 11 11 0110 1001 11 10 10 11 11 0111 10 11 10 10 1001 11
    # xxxx |--| |--| |--| xx xx |--| |--| xx xx xx xx xx |--| xx xx xx xx |--|
    #  10    6    3    3  15 13   6    9  14 10 11 15 13   7  11 14 10 10   9
    #        E    o    o          E    U                   I                U

    bits_expect.(3, "E")
    bits_expect.(6, "Eo")
    bits_expect.(9, "Eoo")
    bits_expect.(12, "EooE")
    bits_expect.(15, "EooEU")
    bits_expect.(18, "EooEUI")
    bits_expect.(20, "EooEUIU")
  end

  test "safe ascii (7 bits)" do
    defmodule(SafeAsciiBytes,
      do: use(Puid.Test.FixedBytes, bytes: <<0xA6, 0x33, 0xF6, 0x9E, 0xBD, 0xED, 0xD7, 0x53>>)
    )

    # shifts: [{90, 7}, {95, 5}, {127, 2}]
    #
    #    A    6    3    3    F    6    9    E    B    D    E    D    D    7    5    3
    # 1010 0110 0011 0011 1111 0110 1001 1110 1011 1101 1110 1101 1101 0111 0101 0011
    #
    # 1010011 0001100  11  11  11  0110100  11  11 0101111 0111101  10111 0101110 1010011
    # |-----| |-----|  xx  xx  xx  |-----|  xx  xx |-----| |-----|  xxxxx |-----| |-----|
    #    83      12   126 123 109    52    122 107    47      61      93     46      83
    #     x       /                   W                R       b              Q       x

    bits_expect = &test_predefined_chars_mod("No escape", :safe_ascii, &1, SafeAsciiBytes, &2)

    bits_expect.(12, "x/")
    bits_expect.(25, "x/WR")
    bits_expect.(28, "x/WRb")
    bits_expect.(34, "x/WRbQ")
    bits_expect.(40, "x/WRbQx")
  end

  test "256 chars" do
    single_byte = Chars.charlist!(:safe64)
    n_single = length(single_byte)

    n_double = 128
    double_start = 0x0100
    double_byte = 0..(n_double - 1) |> Enum.map(&(&1 + double_start))

    n_triple = 64
    triple_start = 0x4DC0
    triple_byte = 0..(n_triple - 1) |> Enum.map(&(&1 + triple_start))

    chars = single_byte ++ double_byte ++ triple_byte

    defmodule(C256Id, do: use(Puid, chars: chars))

    info = C256Id.info()

    assert info.length == String.length(C256Id.generate())
    assert info.entropy_bits_per_char == 8.0
    assert info.ere == 0.5
  end

  test "Invalid total,risk: one missing" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidTotalRisk, do: use(Puid, total: 100))
    end

    assert_raise Puid.Error, fn ->
      defmodule(InvalidTotalRisk, do: use(Puid, risk: 100))
    end
  end

  test "Invalid chars" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: :unknown))
    end
  end

  test "Invalid chars: not unique" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "unique"))
    end
  end

  test "Invalid chars: only one" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "1"))
    end
  end

  test "Calling process not the same as creating process" do
    defmodule(HereId, do: use(Puid))
    assert String.length(HereId.generate()) === HereId.info().length
    spawn(fn -> assert String.length(HereId.generate()) === HereId.info().length end)

    defmodule(HereAlphanumId, do: use(Puid, chars: :alphanum))
    assert String.length(HereAlphanumId.generate()) === HereAlphanumId.info().length

    spawn(fn ->
      assert String.length(HereAlphanumId.generate()) === HereAlphanumId.info().length
    end)
  end

  test "Calling process not the same as creating process: fixed bytes" do
    defmodule(HereVowelBytes,
      do:
        use(Puid.Test.FixedBytes,
          bytes: <<0xA6, 0x33, 0xF6, 0x9E, 0xBD, 0xEE, 0xA7, 0x54, 0x9F, 0x2D>>
        )
    )

    defmodule(HereVowelId,
      do: use(Puid, bits: 15, chars: "aeiouAEIOU", rand_bytes: &HereVowelBytes.rand_bytes/1)
    )

    assert HereVowelId.generate() === "EooEU"
    assert HereVowelId.generate() === "IUAuU"

    spawn(fn -> assert HereVowelId.generate() === "EooEU" end)

    spawn(fn ->
      assert HereVowelId.generate() === "EooEU"
      assert HereVowelId.generate() === "IUAuU"
    end)
  end

  defp test_data(data_dir) do
    data_id_mod = Puid.Test.Data.data_id_mod(data_dir)

    ids_file = Puid.Test.Data.path(Path.join(data_dir, "ids"))

    Puid.Test.Util.data_path(ids_file)
    |> File.stream!()
    |> Stream.map(&String.trim_trailing/1)
    |> Stream.each(fn id -> assert data_id_mod.generate() == id end)
    |> Stream.run()
  end

  @tag :debug
  test "test alphanum using random.bin" do
    test_data("alphanum")
  end
end
