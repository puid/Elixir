defmodule Puid.Test do
  use ExUnit.Case, async: true

  alias Puid.CharSet
  alias Puid.Entropy

  use Bitwise, only: bsl

  def test_charset(charset, length, bits \\ 128) do
    mod = String.to_atom("#{charset}_#{bits}_Id")
    defmodule(mod, do: use(Puid, charset: charset, bits: bits))

    chars = CharSet.chars(charset)
    epbc = Entropy.bits_per_char!(chars)
    eb = length * epbc
    ere = epbc / 8.0
    round_to = 2

    assert mod.info.chars === chars
    assert mod.info.length === length

    assert mod.info.entropy_bits_per_char === Float.round(epbc, round_to)
    assert mod.info.entropy_bits === Float.round(eb, round_to)
    assert mod.info.ere === Float.round(ere, round_to)
    assert mod.generate() |> String.length() === length
  end

  def test_mod_charset_chars(charset) do
    mod = "#{charset |> to_string() |> String.capitalize()}Puid" |> String.to_atom()
    defmodule(mod, do: use(Puid, charset: charset))
    test_mod_chars(mod)
  end

  def test_mod_chars(mod) do
    1..100
    |> Enum.each(fn _ ->
      test_puid_chars(mod.generate(), mod.info().chars)
    end)
  end

  def test_puid_chars(puid, chars) do
    puid
    |> String.graphemes()
    |> Enum.each(fn char -> assert String.contains?(chars, char) end)
  end

  test "pre-defined alpha charset" do
    test_charset(:alpha, 23)
    test_charset(:alpha, 12, 64)
    test_charset(:alpha, 45, 256)
  end

  test "pre-defined lower alpha charset" do
    test_charset(:alpha_lower, 28)
    test_charset(:alpha_lower, 14, 64)
    test_charset(:alpha_lower, 55, 256)
  end

  test "pre-defined upper alpha charset" do
    test_charset(:alpha_upper, 28)
    test_charset(:alpha_upper, 14, 64)
    test_charset(:alpha_upper, 55, 256)
  end

  test "pre-defined alphanum" do
    test_charset(:alphanum, 22)
    test_charset(:alphanum, 11, 64)
    test_charset(:alphanum, 43, 256)
  end

  test "pre-defined lower alphanum" do
    test_charset(:alphanum_lower, 25)
    test_charset(:alphanum_lower, 13, 64)
    test_charset(:alphanum_lower, 50, 256)
  end

  test "pre-defined upper alphanum" do
    test_charset(:alphanum_upper, 25)
    test_charset(:alphanum_upper, 13, 64)
    test_charset(:alphanum_upper, 50, 256)
  end

  test "pre-defined hex" do
    test_charset(:hex, 32)
    test_charset(:hex, 16, 64)
    test_charset(:hex, 64, 256)
  end

  test "pre-defined upper hex" do
    test_charset(:hex_upper, 32)
    test_charset(:hex_upper, 16, 64)
    test_charset(:hex_upper, 64, 256)
  end

  test "pre-defined base32" do
    test_charset(:base32, 26)
    test_charset(:base32, 13, 64)
    test_charset(:base32, 52, 256)
  end

  test "pre-defined base32 hex" do
    test_charset(:base32_hex, 26)
    test_charset(:base32_hex, 13, 64)
    test_charset(:base32_hex, 52, 256)
  end

  test "pre-defined base32 upper hex" do
    test_charset(:base32_hex_upper, 26)
    test_charset(:base32_hex_upper, 13, 64)
    test_charset(:base32_hex_upper, 52, 256)
  end

  test "pre-defined safe32" do
    test_charset(:safe32, 26)
    test_charset(:safe32, 13, 64)
    test_charset(:safe32, 52, 256)
  end

  test "pre-defined safe64" do
    test_charset(:safe64, 22)
    test_charset(:safe64, 11, 64)
    test_charset(:safe64, 43, 256)
  end

  test "pre-defined printable ascii" do
    test_charset(:printable_ascii, 20)
    test_charset(:printable_ascii, 10, 64)
    test_charset(:printable_ascii, 40, 256)
  end

  test "test pre-defined charset mod chars" do
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
      :printable_ascii,
      :safe32,
      :safe64
    ]
    |> Enum.each(&test_mod_charset_chars(&1))
  end

  test "default puid" do
    defmodule(DefaultId, do: use(Puid))
    assert DefaultId.info().chars === CharSet.chars(:safe64)
    assert DefaultId.info().length === 22
    assert DefaultId.info().entropy_bits_per_char === 6.0
    assert DefaultId.info().entropy_bits === 132.0
    assert DefaultId.info().rand_bytes === (&:crypto.strong_rand_bytes/1)
    assert DefaultId.info().ere === 0.75
    assert byte_size(DefaultId.generate()) === DefaultId.info().length
  end

  def test_charset_bytes(descr, charset, bits, bytes_mod, expect) do
    test_chars_bytes(descr, CharSet.chars(charset), bits, bytes_mod, expect)
  end

  def test_chars_bytes(descr, chars, bits, bytes_mod, expect) do
    puid_mod = String.to_atom("#{descr}_#{bits}_bits")

    defmodule(puid_mod,
      do: use(Puid, bits: bits, chars: chars, rand_bytes: &bytes_mod.rand_bytes/1)
    )

    pow2 = &bsl(1, &1)
    char_count = chars |> String.length()

    char_count
    |> :math.log2()
    |> round()
    |> pow2.()
    |> Kernel.==(char_count)
    |> if do
      assert String.reverse(puid_mod.generate()) === expect
    else
      assert puid_mod.generate() === expect
    end

    CryptoRand.clear()
    bytes_mod.reset()
  end

  test "26 lower alpha chars (5 bits)" do
    defmodule(FixedLowerAlphaBytes,
      do: use(FixedBytes, bytes: <<0xF1, 0xB1, 0x78, 0x0A, 0xCE>>)
    )

    bits_expect = &test_charset_bytes("LowerAlpha", :alpha_lower, &1, FixedLowerAlphaBytes, &2)

    # F    1    B    1    7    8    0    A    C    E
    # 1111 0001 1011 0001 0111 1000 0000 1010 1100 1110
    #
    # 1111 00011 01100 01011 11000 00001 01011 00111 0
    # xxxx |---| |---| |---| |---| |---| |---| |---|
    #  30     3    12    11    24     1    11     7
    #         d     m     l     y     b     l     h
    #
    bits_expect.(4, "d")
    bits_expect.(5, "dm")
    bits_expect.(10, "dml")
    bits_expect.(14, "dml")
    bits_expect.(15, "dmly")
    bits_expect.(18, "dmly")
    bits_expect.(19, "dmlyb")
    bits_expect.(24, "dmlybl")
    bits_expect.(28, "dmlybl")
    bits_expect.(32, "dmlyblh")
  end

  test "16 hex chars (5 bits)" do
    defmodule(FixedHexBytes,
      do: use(FixedBytes, bytes: <<0xC7, 0xC9, 0x00, 0x2A>>)
    )

    bits_expect = &test_charset_bytes("Hex", :hex, &1, FixedHexBytes, &2)

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

  test "32 safe32 chars (5 bits)" do
    defmodule(FixedSafe32Bytes,
      do: use(FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x00>>)
    )

    bits_expect = &test_charset_bytes("Safe32", :safe32, &1, FixedSafe32Bytes, &2)

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
    bits_expect.(46, "MhrRBGqL22")
    bits_expect.(50, "MhrRBGqL22")
    bits_expect.(52, "MhrRBGqL222")
  end

  test "32 base32 chars (5 bits)" do
    defmodule(FixedBase32Bytes,
      do: use(FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xDA, 0x19, 0x00>>)
    )

    bits_expect = &test_charset_bytes("Base32", :base32, &1, FixedBase32Bytes, &2)

    bits_expect.(41, "2LR6TWQZA")
    bits_expect.(45, "2LR6TWQZA")
    bits_expect.(46, "2LR6TWQZAA")
    bits_expect.(52, "2LR6TWQZAAA")
  end

  test "64 safe64 chars (6 bits)" do
    defmodule(FixedSafe64Bytes,
      do: use(FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00>>)
    )

    bits_expect = &test_charset_bytes("Safe64", :safe64, &1, FixedSafe64Bytes, &2)

    bits_expect.(24, "0uPp")
    bits_expect.(25, "0uPp-")
    bits_expect.(42, "0uPp-hk")
    bits_expect.(47, "0uPp-hkA")
    bits_expect.(48, "0uPp-hkA")
  end

  test "62 alphanum chars (6 bits)" do
    defmodule(FixedAlphaNumBytes,
      do: use(FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00>>)
    )

    bits_expect = &test_charset_bytes("AlphaNum", :alphanum, &1, FixedAlphaNumBytes, &2)
    # D    2    E    3    E    9    F    A    1    9    0    0
    # 1101 0010 1110 0011 1110 1001 1111 1010 0001 1001 0000 0000
    #
    # 110100 101110 001111 101001 11111 010000 110010 0000000
    # |----| |----| |----| |----| xxxxx |----| |----| |----|
    #   52     46     15     41           16     50      0
    #    0      u      P      p            Q      y      A
    #
    bits_expect.(41, "0uPpQyA")
  end

  test "10 digits chars (4 bits)" do
    defmodule(FixedDigitBytes,
      do: use(FixedBytes, bytes: <<0xA6, 0x33, 0xF6, 0x9E, 0xBD, 0xEE, 0xA7>>)
    )

    bits_expect = &test_chars_bytes("Digit", "0123456789", &1, FixedDigitBytes, &2)

    # A    6    3    3    F    6    9    E    B    D    E    E    A    7
    # 1010 0110 0011 0011 1111 0110 1001 1110 1011 1101 1110 1110 1010 0111
    #
    # 10 1001 1000 11 0011 111 10 11 0100 111 10 10 111 10 111 10 111 0101 0011 1
    # xx |--| |--| xx |--| xxx xx xx |--| xxx xx xx xxx xx xxx xx xxx |--| |--|
    #      9    8       3              4                                5    3
    bits_expect.(3, "9")
    bits_expect.(6, "98")
    bits_expect.(9, "983")
    bits_expect.(12, "9834")
    bits_expect.(15, "98345")
    bits_expect.(18, "983453")
  end

  test "printable ascii chars (7 bits)" do
    defmodule(FixedPrintableBytes,
      do: use(FixedBytes, bytes: <<0xA6, 0x33, 0xF6, 0x9E, 0xBD, 0xEE, 0xA7, 0x53>>)
    )

    bits_expect = &test_charset_bytes("Printable", :printable_ascii, &1, FixedPrintableBytes, &2)

    bits_expect.(12, "t-")
    bits_expect.(26, "t-Ut")
    bits_expect.(27, "t-Utu")
    bits_expect.(32, "t-Utu")
  end

  test "Invalid total,risk: one missing" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidTotalRisk, do: use(Puid, total: 100))
    end

    assert_raise Puid.Error, fn ->
      defmodule(InvalidTotalRisk, do: use(Puid, risk: 100))
    end
  end

  test "Invalid charset" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidCharSet, do: use(Puid, charset: :unknown))
    end
  end

  test "Invalid chars: not unique" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "abcdefghiaklmn"))
    end
  end

  test "Invalid chars: only one" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidChars, do: use(Puid, chars: "1"))
    end
  end
end
