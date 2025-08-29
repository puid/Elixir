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
defmodule Puid.Test.Puid do
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

    assert mod.info().char_set === char_set
    assert mod.info().length === length

    assert mod.info().entropy_bits_per_char === Float.round(epbc, round_to)
    assert mod.info().entropy_bits === Float.round(eb, round_to)
    assert mod.info().ere === Float.round(ere, round_to)
    assert mod.generate() |> String.length() === length
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

  test "pre-defined crockford32" do
    test_char_set(:crockford32, 26)
    test_char_set(:crockford32, 13, 64)
    test_char_set(:crockford32, 52, 256)
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

  test "pre-defined symbol" do
    test_char_set(:symbol, 27)
    test_char_set(:symbol, 14, 64)
    test_char_set(:symbol, 54, 256)
  end

  test "pre-defined wordSafe32" do
    test_char_set(:wordSafe32, 26)
    test_char_set(:wordSafe32, 13, 64)
    test_char_set(:wordSafe32, 52, 256)
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
      :crockford32,
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

  test "encode" do
    defmodule(IdEncoder, do: use(Puid, bits: 55, chars: :alpha_lower))

    puid_bits = <<141, 138, 2, 168, 7, 11, 13, 0::size(4)>>
    puid = "rwfafkahbmgq"

    assert IdEncoder.encode(puid_bits) == puid
  end

  test "encode fail" do
    defmodule(FailEncoder, do: use(Puid, bits: 34, chars: :alpha))

    puid_bits = <<76, 51, 24, 70, 2::size(4)>>
    assert FailEncoder.encode(puid_bits) == "TDMYRi"

    assert FailEncoder.encode(<<76, 51, 24, 70, 2::size(3)>>) == {:error, "unable to encode"}
    assert FailEncoder.encode(<<76, 51, 24, 70, 2::size(5)>>) == {:error, "unable to encode"}

    assert FailEncoder.encode(<<76, 51, 24, 255, 2::size(4)>>) == {:error, "unable to encode"}
  end

  test "decode" do
    defmodule(IdDecoder, do: use(Puid, bits: 62, chars: :alphanum))

    bits = <<70, 114, 103, 8, 162, 67, 146, 76, 3::size(2)>>
    puid = "RnJnCKJDkkz"

    assert IdDecoder.decode(puid) == bits
  end

  test "decode fail" do
    defmodule(FailDecoder, do: use(Puid, bits: 34, chars: :alpha))

    puid = FailDecoder.generate()

    long = puid <> "1"
    assert FailDecoder.decode(long) == {:error, "unable to decode"}

    <<_::binary-size(1), short::binary>> = puid
    assert FailDecoder.decode(short) == {:error, "unable to decode"}

    invalid_char = short <> "$"
    assert FailDecoder.decode(invalid_char) == {:error, "unable to decode"}
  end

  test "decode not supported" do
    defmodule(DNoNo, do: use(Puid, bits: 50, chars: ~c"dîngøsky"))

    assert DNoNo.generate() |> DNoNo.decode() ==
             {:error, "not supported for non-ascii characters sets"}
  end

  test "decode/encode round trips" do
    defmodule(EDHex, do: use(Puid, chars: :hex))
    hexId = EDHex.generate()
    assert hexId |> EDHex.decode() |> EDHex.encode() == hexId

    defmodule(EDAscii, do: use(Puid, chars: :safe_ascii))
    asciiId = EDAscii.generate()
    assert asciiId |> EDAscii.decode() |> EDAscii.encode() == asciiId
  end

  test "total/risk" do
    defmodule(TotalRiskId, do: use(Puid, total: 10_000, risk: 1.0e12, chars: :alpha))

    info = TotalRiskId.info()
    assert info.entropy_bits === 68.41
    assert info.entropy_bits_per_char == 5.7
    assert info.ere == 0.71
    assert info.length == 12
  end

  test "total/risk approximations" do
    total = 1_000_000
    risk = 1.0e12

    defmodule(ApproxTotalRisk, do: use(Puid, total: total, risk: risk, chars: :safe32))

    assert ApproxTotalRisk.total(risk) == 1_555_013
    assert ApproxTotalRisk.risk(total) == 2_418_040_068_387
  end

  test "unicode chars" do
    chars = "noe\u0308l"
    defmodule(XMasChars, do: use(Puid, chars: chars))

    info = XMasChars.info()
    assert info.characters == chars
    assert info.char_set == :custom
    assert info.length == 56
  end

  test "unicode dog" do
    chars = "dîngøsky:\u{1F415}"
    defmodule(DingoSkyDog, do: use(Puid, total: 1.0e9, risk: 1.0e15, chars: chars))

    info = DingoSkyDog.info()
    assert info.characters == chars
    assert info.char_set == :custom
    assert info.entropy_bits == 109.62
    assert info.entropy_bits_per_char == 3.32
    assert info.ere == 0.28
    assert info.length == 33
  end

  test "Invalid total,risk: one missing" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidTotalRisk, do: use(Puid, total: 100))
    end

    assert_raise Puid.Error, fn ->
      defmodule(InvalidTotalRisk, do: use(Puid, risk: 100))
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

  test "Invalid chars: unknown" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: :unknown))
    end
  end

  test "Invalid ascii chars" do
    # Below bang
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "!# $"))
    end

    # Include double-quote
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "!\"#$"))
    end

    # Include single-quote
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "!\'#$"))
    end

    # Include backslash
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "!#\\$"))
    end

    # Include back-tick
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "!#`$"))
    end
  end

  test "Invalid chars: out of range" do
    # Between tilde and inverted bang
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "!#$~\u0099\u00a1"))
    end
  end

  test "invalid chars" do
    assert_raise Puid.Error, fn ->
      defmodule(NoNoId, do: use(Puid, chars: ~c"dingo\n"))
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

  test "alpha" do
    defmodule(AlphaBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xF1, 0xB1, 0x78, 0x0A, 0xCE, 0x2B>>)
    )

    defmodule(Alpha14Id,
      do: use(Puid, bits: 14, chars: :alpha, rand_bytes: &AlphaBytes.rand_bytes/1)
    )

    assert Alpha14Id.generate() === "jYv"
    assert Alpha14Id.generate() === "AVn"
  end

  test "26 lower alpha chars (5 bits)" do
    defmodule(LowerAlphaBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xF1, 0xB1, 0x78, 0x0B, 0xAA>>)
    )

    bits_expect = &test_predefined_chars_mod("LowerAlpha", :alpha_lower, &1, LowerAlphaBytes, &2)

    # shifts:[{25, 5}, {27, 4}, {31, 3}]
    #
    #    F    1    B    1    7    8    0    B    A    A
    # 1111 0001 1011 0001 0111 1000 0000 1011 1010 1010
    #
    # 111 10001 10110 00101 111 00000 00101 1101 01010
    # xxx |---| |---| |---| xxx |---| |---| xxxx |---|
    #  30   17    22     5   30    0     5    26   10
    #        r     w     f         a     f          k
    #
    bits_expect.(4, "r")
    bits_expect.(5, "rw")
    bits_expect.(10, "rwf")
    bits_expect.(14, "rwf")
    bits_expect.(15, "rwfa")
    bits_expect.(18, "rwfa")
    bits_expect.(19, "rwfaf")
    bits_expect.(24, "rwfafk")
  end

  test "lower alpha carry (26 chars, 5 bits)" do
    defmodule(LowerAlphaCarryBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xF1, 0xB1, 0x78, 0x0A, 0xCE>>)
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

  test "upper alpha" do
    defmodule(UpperAlphaBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xF1, 0xB1, 0x78, 0x0A, 0xCE>>)
    )

    defmodule(UpperAlphaId,
      do:
        use(Puid,
          bits: 14,
          chars: :alpha_upper,
          rand_bytes: &UpperAlphaBytes.rand_bytes/1
        )
    )

    assert UpperAlphaId.generate() === "RWF"
    assert UpperAlphaId.generate() === "AFM"
  end

  test "62 alphanum chars (6 bits)" do
    defmodule(AlphaNumBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00>>)
    )

    bits_expect = &test_predefined_chars_mod("AlphaNum", :alphanum, &1, AlphaNumBytes, &2)

    # shifts: [{61, 6}, {63, 5}]
    #
    #    D    2    E    3    E    9    F    A    1    9    0    0
    # 1101 0010 1110 0011 1110 1001 1111 1010 0001 1001 0000 0000
    #
    # 110100 101110 001111 101001 11111 010000 110010 000000 0
    # |----| |----| |----| |----| xxxxx |----| |----| |----|
    #   52     46     15     41     62     16     50      0
    #    0      u      P      p             Q      y      A
    #
    bits_expect.(41, "0uPpQyA")
  end

  test "alphanum chars (62 chars, 6 bits) carry" do
    defmodule(AlphaNumCarryBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x1F, 0xAC>>)
    )

    defmodule(AlphaNumCarryId,
      do: use(Puid, bits: 12, chars: :alphanum, rand_bytes: &AlphaNumCarryBytes.rand_bytes/1)
    )

    # shifts: [{61, 6}, {63, 5}]
    #
    #    D    2    E    3    E    9    F    A    1    F    A    C
    # 1101 0010 1110 0011 1110 1001 1111 1010 0001 1111 1010 1100
    #
    # 110100 101110 001111 101001 11111 010000 11111 101011 00
    # |----| |----| |----| |----| xxxxx |----| xxxxx |----|
    #   52     46     15     41     62     16    63     43
    #    0      u      P      p             Q            r
    #
    assert AlphaNumCarryId.generate() == "0uP"
    assert AlphaNumCarryId.generate() == "pQr"
  end

  test "alpha lower" do
    defmodule(AlphaLowerBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0x53, 0xC8, 0x8D, 0xE6, 0x3E, 0x27, 0xEF>>)
    )

    defmodule(AlphaLower14Id,
      do: use(Puid, bits: 14, chars: :alpha_lower, rand_bytes: &AlphaLowerBytes.rand_bytes/1)
    )

    # shifts: [{25, 5}, {27, 4}, {31, 3}])
    #
    #    5    3    c    8    8    d    e    6    3    e    2    7    e    f
    # 0101 0011 1100 1000 1000 1101 1110 0110 0011 1110 0010 0111 1110 1111
    #
    # 01010 01111 00100 01000 1101 111 00110 00111 11000 10011 111 10111 1
    # |---| |---| |---| |---| xxxx xxx |---| |---| |---| |---| xxx |---|
    #   10    15     4     8   27   28    6     7    24    19   30   23
    #    k     p     e     i              g     h     y     t         x

    assert AlphaLower14Id.generate() == "kpe"
    assert AlphaLower14Id.generate() == "igh"
    assert AlphaLower14Id.generate() == "ytx"
  end

  test "alphanum lower" do
    defmodule(AlphaNumLowerBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00, 0xC8, 0x2D>>)
    )

    defmodule(AlphaNumLowerId,
      do:
        use(Puid, bits: 12, chars: :alphanum_lower, rand_bytes: &AlphaNumLowerBytes.rand_bytes/1)
    )

    assert AlphaNumLowerId.generate() == "s9p"
    assert AlphaNumLowerId.generate() == "qib"
  end

  test "alphanum upper" do
    defmodule(AlphaNumUpperBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00, 0xC8, 0x2D>>)
    )

    defmodule(AlphaNumUpperId,
      do:
        use(Puid, bits: 12, chars: :alphanum_upper, rand_bytes: &AlphaNumUpperBytes.rand_bytes/1)
    )

    assert AlphaNumUpperId.generate() == "S9P"
    assert AlphaNumUpperId.generate() == "QIB"
  end

  test "base32 chars (5 bits)" do
    defmodule(Base32Bytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x00, 0x22>>)
    )

    bits_expect = &test_predefined_chars_mod("Base32", :base32, &1, Base32Bytes, &2)

    bits_expect.(41, "2LR6TWQZA")
    bits_expect.(45, "2LR6TWQZA")
    bits_expect.(46, "2LR6TWQZAA")
  end

  test "base32 hex" do
    defmodule(Base32HexBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C>>)
    )

    defmodule(Base32HexId,
      do: use(Puid, bits: 30, chars: :base32_hex, rand_bytes: &Base32HexBytes.rand_bytes/1)
    )

    assert Base32HexId.generate() == "qbhujm"
    assert Base32HexId.generate() == "gp0erj"
  end

  test "base32 hex upper" do
    defmodule(Base32HexUpperBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C>>)
    )

    defmodule(Base32HexUpperId,
      do:
        use(Puid,
          bits: 14,
          chars: :base32_hex_upper,
          rand_bytes: &Base32HexUpperBytes.rand_bytes/1
        )
    )

    assert Base32HexUpperId.generate() == "QBH"
    assert Base32HexUpperId.generate() == "UJM"
    assert Base32HexUpperId.generate() == "GP0"
    assert Base32HexUpperId.generate() == "ERJ"
  end

  test "crockford 32" do
    defmodule(Crockford32Bytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C>>)
    )

    defmodule(Crockford32Id,
      do:
        use(Puid,
          bits: 20,
          chars: :crockford32,
          rand_bytes: &Crockford32Bytes.rand_bytes/1
        )
    )

    assert Crockford32Id.generate() == "TBHY"
    assert Crockford32Id.generate() == "KPGS"
    assert Crockford32Id.generate() == "0EVK"
  end

  test "decimal" do
    defmodule(DecimalBytes,
      do:
        use(Puid.Util.FixedBytes,
          bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C, 0xFF, 0x22>>
        )
    )

    # shifts: [{9, 4}, {11, 3}, {15, 2}]
    #
    #    D    2    E    3    E    9    D    A    1    9    0    3    B    7    3    C    F    F
    # 1101 0010 1110 0011 1110 1001 1101 1010 0001 1001 0000 0011 1011 0111 0011 1100 1111 1111
    #
    # 11 0100 101 11 0001 11 11 0100 11 101 101 0000 11 0010 0000 0111 0110 11 1001 11 1001 111 1111
    # xx |--| xxx xx |--| xx xx |--| xx xxx xxx |--| xx |--| |--| |--| |--| xx |--| xx |--|
    # 13   4   11 12   1  15 13   4  14  11  10   0  12   2    0    7    6  14   9  14   9
    #      4           1          4               0       2    0    7    6       9       9

    defmodule(DecimalId,
      do: use(Puid, bits: 16, chars: :decimal, rand_bytes: &DecimalBytes.rand_bytes/1)
    )

    assert DecimalId.generate() == "41402"
    assert DecimalId.generate() == "07699"
  end

  test "hex chars without carry" do
    defmodule(HexNoCarryBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD>>)
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
      do: use(Puid.Util.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD>>)
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

  test "hex chars, variable bits" do
    defmodule(FixedHexBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A>>)
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

  test "hex upper" do
    defmodule(HexUpperBytes,
      do:
        use(Puid.Util.FixedBytes,
          bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0x16, 0x32>>
        )
    )

    defmodule(HexUpperId,
      do: use(Puid, bits: 16, chars: :hex_upper, rand_bytes: &HexUpperBytes.rand_bytes/1)
    )

    assert HexUpperId.generate() == "C7C9"
    assert HexUpperId.generate() == "002A"
    assert HexUpperId.generate() == "1632"
  end

  test "safe ascii" do
    defmodule(SafeAsciiBytes,
      do:
        use(Puid.Util.FixedBytes, bytes: <<0xA6, 0x33, 0x2A, 0xBE, 0xE6, 0x2D, 0xB3, 0x68, 0x41>>)
    )

    # shifts: [{89, 7}, {91, 6}, {95, 5}, {127, 2}]
    #
    #    A    6    3    3   2    A    B    E    E    6    2    D    B    3    6    8
    # 1010 0110 0011 0011 0010 1010 1011 1110 1110 0110 0010 1101 1011 0011 0110 1000 0100 0001
    #
    # 1010011 0001100  11 0010010 0101111 10111 0011000 101101 1011001 101101 0000100 0001
    # |-----| |-----|  xx |-----| |-----| xxxxx |-----| xxxxxx |-----| xxxxxx |-----|
    #    83      12   101    21      47     92     24      91     89      90      4
    #     x       /           8       R             ;              ~              &

    bits_expect = &test_predefined_chars_mod("SafeAscii", :safe_ascii, &1, SafeAsciiBytes, &2)

    bits_expect.(6, "x")
    bits_expect.(12, "x/")
    bits_expect.(18, "x/8")
    bits_expect.(22, "x/8R")
    bits_expect.(26, "x/8R;")
    bits_expect.(34, "x/8R;~")
    bits_expect.(40, "x/8R;~&")
  end

  test "safe32 chars (5 bits)" do
    defmodule(Safe32Bytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C>>)
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

  test "safe32 with carry" do
    defmodule(Safe32NoCarryBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C>>)
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

  @tag :only
  test "wordSafe32 chars (5 bits)" do
    defmodule(WordSafe32Bytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x03, 0xB7, 0x3C>>)
    )

    #    D    2    E    3    E    9    D    A    1    9    0    3    B    7    3    C
    # 1101 0010 1110 0011 1110 1001 1101 1010 0001 1001 0000 0011 1011 0111 0011 1100
    #
    # 11010 01011 10001 11110 10011 10110 10000 11001 00000 01110 11011 10011 1100
    # |---| |---| |---| |---| |---| |---| |---| |---| |---| |---| |---| |---|
    #  26    11    17    30    19    22    16    25     0    14    27    19
    #   p     H     V     w     X     g     R     m     2     P     q     X

    bits_expect = &test_predefined_chars_mod("WordSafe32", :wordSafe32, &1, WordSafe32Bytes, &2)

    bits_expect.(58, "pHVwXgRm2PqX")
  end

  test "safe64 chars (6 bits)" do
    defmodule(Safe64Bytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00>>)
    )

    bits_expect = &test_predefined_chars_mod("Safe64", :safe64, &1, Safe64Bytes, &2)

    bits_expect.(24, "0uPp")
    bits_expect.(25, "0uPp-")
    bits_expect.(42, "0uPp-hk")
    bits_expect.(47, "0uPp-hkA")
    bits_expect.(48, "0uPp-hkA")
  end

  test "TF chars without carry" do
    defmodule(TFNoCarryBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0b11111011, 0b00000100, 0b00101100, 0b10110011>>)
    )

    defmodule(TFNoCarryId,
      do: use(Puid, bits: 16, chars: ~c"FT", rand_bytes: &TFNoCarryBytes.rand_bytes/1)
    )

    assert TFNoCarryId.generate() == "TTTTTFTTFFFFFTFF"
    assert TFNoCarryId.generate() == "FFTFTTFFTFTTFFTT"
  end

  test "DingoSky chars without carry" do
    defmodule(DingoSkyNoCarryBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD, 0x72>>)
    )

    #    C    7    C    9    0    0    2    A    B    D    7    2
    # 1100 0111 1100 1001 0000 0000 0010 1010 1011 1101 0111 0010
    #
    # 110 001 111 100 100 100 000 000 001 010 101 011 110 101 110 010
    # |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-|
    #  k   i   y   o   o   o   d   d   i   n   s   g   k   s   k   n

    defmodule(DingoSkyNoCarryId,
      do: use(Puid, bits: 24, chars: ~c"dingosky", rand_bytes: &DingoSkyNoCarryBytes.rand_bytes/1)
    )

    assert DingoSkyNoCarryId.generate() == "kiyooodd"
    assert DingoSkyNoCarryId.generate() == "insgkskn"
  end

  test "dingosky chars with carry" do
    defmodule(DingoSkyCarryBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD, 0x72>>)
    )

    #    C    7    C    9    0    0    2    A    B    D    7    2
    # 1100 0111 1100 1001 0000 0000 0010 1010 1011 1101 0111 0010
    #
    # 110 001 111 100 100 100 000 000 001 010 101 011 110 101 110 010
    # |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-|
    #  k   i   y   o   o   o   d   d   i   n   s   g   k   s   k   n

    defmodule(DingoSkyCarryId,
      do: use(Puid, bits: 9, chars: ~c"dingosky", rand_bytes: &DingoSkyCarryBytes.rand_bytes/1)
    )

    assert DingoSkyCarryId.generate() == "kiy"
    assert DingoSkyCarryId.generate() == "ooo"
    assert DingoSkyCarryId.generate() == "ddi"
    assert DingoSkyCarryId.generate() == "nsg"
    assert DingoSkyCarryId.generate() == "ksk"
  end

  test "dîngøsky chars with carry" do
    defmodule(DingoSkyUtf8Bytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A, 0xBD, 0x72>>)
    )

    #    C    7    C    9    0    0    2    A    B    D    7    2
    # 1100 0111 1100 1001 0000 0000 0010 1010 1011 1101 0111 0010
    #
    # 110 001 111 100 100 100 000 000 001 010 101 011 110 101 110 010
    # |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-| |-|
    #  k   î   y   ø   ø   ø   d   d   î   n   s   g   k   s   k   n

    defmodule(DingoskyUtf8CarryId,
      do: use(Puid, bits: 9, chars: ~c"dîngøsky", rand_bytes: &DingoSkyUtf8Bytes.rand_bytes/1)
    )

    assert DingoskyUtf8CarryId.generate() == "kîy"
    assert DingoskyUtf8CarryId.generate() == "øøø"
    assert DingoskyUtf8CarryId.generate() == "ddî"
    assert DingoskyUtf8CarryId.generate() == "nsg"
    assert DingoskyUtf8CarryId.generate() == "ksk"
  end

  test "dîngøsky:🐕" do
    defmodule(DogBytes,
      do:
        use(Puid.Util.FixedBytes,
          bytes:
            <<0xEC, 0xF9, 0xDB, 0x7A, 0x33, 0x3D, 0x21, 0x97, 0xA0, 0xC2, 0xBF, 0x92, 0x80, 0xDD,
              0x2F, 0x57, 0x12, 0xC1, 0x1A, 0xEF>>
        )
    )

    defmodule(DogId,
      do: use(Puid, bits: 24, chars: ~c"dîngøsky:🐕", rand_bytes: &DogBytes.rand_bytes/1)
    )

    assert DogId.generate() == "🐕gî🐕🐕nî🐕"
    assert DogId.generate() == "ydkîsnsd"
    assert DogId.generate() == "îøsîndøk"
  end

  test "10 custom vowels chars (4 bits)" do
    defmodule(VowelBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xA6, 0x33, 0xF6, 0x9E, 0xBD, 0xEE, 0xA7>>)
    )

    bits_expect = &test_custom_chars_mod("Vowels", "aeiouAEIOU", &1, VowelBytes, &2)

    # shifts: [{9, 4}, {11, 3}, {15, 2}]
    #
    #    A    6    3    3    F    6    9    E    B    D    E    E    A    7
    # 1010 0110 0011 0011 1111 0110 1001 1110 1011 1101 1110 1110 1010 0111
    #
    # 101 0011 0001 1001 11 11 101 101 0011 11 0101 11 101 11 101 11 0101 0011 1
    # xxx |--| |--| |--| xx xx xxx xxx |--| xx |--| xx xxx xx xxx xx |--| |--|
    #  10   3    1    9  15 14  11  10   3  13   5  14  11 14  11 13   5    3
    #       o    e    U                  o       A                     A    o
    #

    bits_expect.(3, "o")
    bits_expect.(6, "oe")
    bits_expect.(9, "oeU")
    bits_expect.(12, "oeUo")
    bits_expect.(15, "oeUoA")
    bits_expect.(18, "oeUoAA")
    bits_expect.(20, "oeUoAAo")
  end

  test "256 chars" do
    defmodule(SomeBytes,
      do:
        use(Puid.Util.FixedBytes,
          bytes:
            <<0xEC, 0xF9, 0xDB, 0x7A, 0x33, 0x3D, 0x21, 0x97, 0xA0, 0xC2, 0xBF, 0x92, 0x80, 0xDD,
              0x2F, 0x57, 0x12, 0xC1, 0x1A, 0xEF>>
        )
    )

    single_byte = Chars.charlist!(:safe64)
    n_single = length(single_byte)

    n_double = 128
    double_start = 0x0100
    double_byte = 0..(n_double - 1) |> Enum.map(&(&1 + double_start))

    n_triple = 64
    triple_start = 0x4DC0
    triple_byte = 0..(n_triple - 1) |> Enum.map(&(&1 + triple_start))

    chars = single_byte ++ double_byte ++ triple_byte

    defmodule(C256Id, do: use(Puid, bits: 36, chars: chars, rand_bytes: &SomeBytes.rand_bytes/1))

    info = C256Id.info()

    assert info.length == 5
    assert info.entropy_bits_per_char == 8.0
    assert info.ere == 0.5

    assert C256Id.generate() == "䷬䷹䷛ĺz"
    assert C256Id.generate() == "9hŗŠ䷂"
    assert C256Id.generate() == "ſŒŀ䷝v"
    assert C256Id.generate() == "ėS䷁a䷯"
  end

  # This doesn't actually test the modules, but defines each case as per issue #12
  test "Cover all chunk sizings" do
    defmodule(LessSingleId, do: use(Puid, bits: 5, chars: :safe64))
    defmodule(SingleId, do: use(Puid, bits: 40, chars: :safe32))
    defmodule(LessPairId, do: use(Puid, bits: 40, chars: "dingoskyme"))
    defmodule(EqualPairId, do: use(Puid, bits: 64, chars: :hex))
    defmodule(EqualPairsId, do: use(Puid, bits: 128, chars: :hex))
    defmodule(LessPairsPlusSingleId, do: use(Puid, bits: 148, chars: :hex))
    defmodule(EqualPairPlusSingleId, do: use(Puid, bits: 140, chars: :alphanum))
    defmodule(EqualPairsPlusSingleId, do: use(Puid, bits: 196, chars: :wordSafe32))
    defmodule(GreaterPairsPlusSingleId, do: use(Puid, bits: 220, chars: :safe32))
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
        use(Puid.Util.FixedBytes,
          bytes: <<0xA6, 0x33, 0xF6, 0x9E, 0xBD, 0xEE, 0xA7, 0x54, 0x9F, 0x2D>>
        )
    )

    defmodule(HereVowelId,
      do: use(Puid, bits: 15, chars: "aeiouAEIOU", rand_bytes: &HereVowelBytes.rand_bytes/1)
    )

    assert HereVowelId.generate() === "oeUoA"
    assert HereVowelId.generate() === "AoAiI"

    spawn(fn -> assert HereVowelId.generate() === "oeUoA" end)

    spawn(fn ->
      assert HereVowelId.generate() === "oeUoA"
      assert HereVowelId.generate() === "AoAiI"
    end)
  end
end
