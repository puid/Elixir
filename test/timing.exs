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
defmodule Puid.Test.Timing do
  use ExUnit.Case

  def time(function, label) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
    |> IO.inspect(label: label)
  end

  def common_solution(len, chars) do
    chars_count = String.length(chars)

    for(_ <- 1..len, do: :rand.uniform(chars_count) - 1)
    |> Enum.map(&(chars |> String.at(&1)))
    |> List.to_string()
  end

  @tag :common_solution
  test "compare to common solution using alphanumeric characters" do
    trials = 100_000

    defmodule(AlphanumPuid128_CS, do: use(Puid, chars: :alphanum))

    defmodule(AlphanumPrngPuid128_CS,
      do: use(Puid, chars: :alphanum, rand_bytes: &:rand.bytes/1)
    )

    chars = AlphanumPuid128_CS.info().characters
    len = AlphanumPuid128_CS.info().length
    common = fn -> for(_ <- 1..trials, do: common_solution(len, chars)) end
    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128_CS.generate()) end
    prng_puid = fn -> for(_ <- 1..trials, do: AlphanumPrngPuid128_CS.generate()) end

    IO.puts("\n--- Common Solution ---")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using alphanumeric characters"
    )

    :rand.seed(:exsss)
    IO.puts("")
    time(common, "    Common Solution   (PRNG) ")
    time(prng_puid, "    Puid              (PRNG) ")
    IO.puts("")
    :crypto.rand_seed()
    time(common, "    Common Solution (CSPRNG) ")
    time(puid, "    Puid            (CSPRNG) ")
  end

  @tag :entropy_string
  test "compare to :entropy_string" do
    trials = 100_000

    IO.puts("\n--- EntropyString ---")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using #{:safe64} characters"
    )

    defmodule(Safe64ES, do: use(EntropyString, chars: :charset64))
    defmodule(Safe64Puid128_ES, do: use(Puid, chars: :safe64))

    entropy_string = fn -> for(_ <- 1..trials, do: Safe64ES.random()) end
    puid = fn -> for(_ <- 1..trials, do: Safe64Puid128_ES.generate()) end

    IO.puts("")
    time(entropy_string, "    Entropy String (CSPRNG) ")
    time(puid, "    Puid           (CSPRNG) ")

    defmodule(DingoskyPuid64, do: use(Puid, bits: 64, chars: "dingosky"))

    chars = DingoskyPuid64.info().characters
    defmodule(CustomES64, do: use(EntropyString, bits: 64, chars: chars))

    IO.puts(
      "\n  Generate #{trials} random IDs with 64 bits of entropy using #{String.length(chars)} custom characters"
    )

    entropy_string = fn -> for(_ <- 1..trials, do: CustomES64.random()) end
    puid = fn -> for(_ <- 1..trials, do: DingoskyPuid64.generate()) end

    IO.puts("")
    time(entropy_string, "    Entropy String (CSPRNG) ")
    time(puid, "    Puid           (CSPRNG) ")
  end

  def gen_reference() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end

  @tag :gen_reference
  test "compare to gen_reference" do
    trials = 500_000

    IO.puts("\n--- gen_reference ---")

    IO.puts(
      "\n  Generate #{trials} random IDs with 31 bits of entropy using #{:alphanum_upper} characters"
    )

    gen_reference = fn -> for(_ <- 1..trials, do: gen_reference()) end

    defmodule(UpperAlphanumPRNGPuid31,
      do: use(Puid, bits: 31, chars: :alphanum_upper, rand_bytes: &:rand.bytes/1)
    )

    prng_puid = fn -> for(_ <- 1..trials, do: UpperAlphanumPRNGPuid31.generate()) end

    defmodule(UpperAlphanumPuid31, do: use(Puid, bits: 31, chars: :alphanum_upper))
    puid = fn -> for(_ <- 1..trials, do: UpperAlphanumPuid31.generate()) end

    IO.puts("")
    :rand.seed(:exsss)
    time(gen_reference, "    gen_reference   (PRNG) ")
    time(prng_puid, "    Puid            (PRNG) ")
    IO.puts("")
    :crypto.rand_seed()
    time(gen_reference, "    gen_reference (CSPRNG) ")
    time(puid, "    Puid          (CSPRNG) ")

    IO.puts("\n  Generate #{trials} random IDs with 31 bits of entropy using :safe32 characters")
    defmodule(Safe32Puid, do: use(Puid, bits: 31, chars: :safe32))
    safe32_puid = fn -> for(_ <- 1..trials, do: Safe32Puid.generate()) end

    IO.puts("")
    time(gen_reference, "    gen_reference (CSPRNG) ")
    time(safe32_puid, "    Puid safe32   (CSPRNG) ")
  end

  @tag :misc_random
  test "compare to Misc.Random alphanum" do
    trials = 30_000

    IO.puts("\n--- Misc.Random ---")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using #{:alphanum} characters"
    )

    defmodule(AlphanumPrngPuid128_MR,
      do: use(Puid, chars: :alphanum, rand_bytes: &:rand.bytes/1)
    )

    defmodule(AlphanumPuid128_MR, do: use(Puid, chars: :alphanum))

    misc_random = fn -> for(_ <- 1..trials, do: Misc.Random.string(22)) end
    prng_puid = fn -> for(_ <- 1..trials, do: AlphanumPrngPuid128_MR.generate()) end
    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128_MR.generate()) end

    IO.puts("")
    :rand.seed(:exsss)
    time(misc_random, "    Misc.Random (PRNG) ")
    time(prng_puid, "    Puid        (PRNG) ")

    IO.puts("")
    :crypto.rand_seed()
    time(misc_random, "    Misc.Random (CSPRNG) ")
    time(puid, "    Puid        (CSPRNG) ")
  end

  @tag :debug
  test "CxDebug" do
    NotQwerty123.RandomPassword.gen_password() |> IO.inspect(label: "?")
  end

  @tag :not_qwerty123
  test "compare to NotQwerty123" do
    trials = 50_000

    defmodule(AlphanumPuid128_NQ, do: use(Puid, chars: :alphanum))
    defmodule(NoEscapePuid128_NQ, do: use(Puid, chars: :safe_ascii))

    IO.puts("\n--- NotQwerty123 ---")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using #{:alphanum} characters"
    )

    not_querty_alphanum = fn ->
      for(_ <- 1..trials, do: NotQwerty123.RandomPassword.gen_password(length: 22))
    end

    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128_NQ.generate()) end

    IO.puts("")
    time(not_querty_alphanum, "    NotQwerty123 (CSPRNG) ")
    time(puid, "    Puid         (CSPRNG) ")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using #{:safe_ascii} characters"
    )

    not_querty_printable = fn ->
      for(
        _ <- 1..trials,
        do: NotQwerty123.RandomPassword.gen_password(length: 20, characters: :letters_digits_punc)
      )
    end

    puid = fn -> for(_ <- 1..trials, do: NoEscapePuid128_NQ.generate()) end

    IO.puts("")
    time(not_querty_printable, "    NotQwerty123 (CSPRNG) ")
    time(puid, "    Puid         (CSPRNG) ")
  end

  @tag :randomizer
  test "compare to Randomizer" do
    trials = 100_000

    IO.puts("\n--- randomizer ---")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using #{:alphanum} characters"
    )

    defmodule(AlphanumPuid128_R, do: use(Puid, chars: :alphanum))

    defmodule(AlphanumPrngPuid128_R, do: use(Puid, chars: :alphanum, rand_bytes: &:rand.bytes/1))

    randomizer = fn -> for(_ <- 1..trials, do: Randomizer.generate!(22)) end
    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128_R.generate()) end
    prng_puid = fn -> for(_ <- 1..trials, do: AlphanumPrngPuid128_R.generate()) end

    IO.puts("")
    :rand.seed(:exsss)
    time(randomizer, "    Randomizer   (PRNG) ")
    time(prng_puid, "    Puid         (PRNG) ")

    IO.puts("")
    :crypto.rand_seed()
    time(randomizer, "    Randomizer (CSPRNG) ")
    time(puid, "    Puid       (CSPRNG) ")
  end

  @tag :secure_random
  test "compare to SecureRandom safe64" do
    trials = 500_000

    IO.puts("\n--- secure_random ---")

    IO.puts("\n  Generate #{trials} random IDs with 128 bits of entropy using #{:hex} characters")

    defmodule(HexPuid128_SR, do: use(Puid, chars: :hex))
    defmodule(Safe64Puid128_SR, do: use(Puid, chars: :safe64))

    hex_secure_random = fn -> for(_ <- 1..trials, do: SecureRandom.hex(16)) end
    hex_puid = fn -> for(_ <- 1..trials, do: HexPuid128_SR.generate()) end

    IO.puts("")
    time(hex_secure_random, "    SecureRandom (CSPRNG) ")
    time(hex_puid, "    Puid         (CSPRNG) ")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using #{:safe64} characters"
    )

    secure_random = fn -> for(_ <- 1..trials, do: SecureRandom.urlsafe_base64()) end
    puid = fn -> for(_ <- 1..trials, do: Safe64Puid128_SR.generate()) end

    IO.puts("")
    time(secure_random, "    SecureRandom (CSPRNG) ")
    time(puid, "    Puid         (CSPRNG) ")
  end

  @tag :custom_chars
  test "compare Puid hex to 16 custom chars" do
    trials = 500_000

    IO.puts("\n--- Custom chars vs pre-defined with same length ---")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using hex vs 16 custom characters"
    )

    defmodule(CustomPuid128, do: use(Puid, bits: 128, chars: "DINGOSKYdingosky"))
    defmodule(HexPuid128_CC, do: use(Puid, chars: :hex))

    custom_puid = fn -> for(_ <- 1..trials, do: CustomPuid128.generate()) end
    hex_puid = fn -> for(_ <- 1..trials, do: HexPuid128_CC.generate()) end

    IO.puts("")
    time(hex_puid, "    Puid hex    ")
    time(custom_puid, "    Puid custom ")
  end

  @tag :prng_csprng
  test "compare Puid PRNG to CSPRNG with hex chars" do
    trials = 500_000

    IO.puts("\n--- Puid PRNG vs CSPRNG ---")

    IO.puts(
      "\n  Generate #{trials} random IDs with 128 bits of entropy using hex vs 16 custom characters"
    )

    defmodule(HexPrngPuid128, do: use(Puid, chars: :hex, rand_bytes: &:rand.bytes/1))

    defmodule(CustomPrngPuid128,
      do: use(Puid, bits: 128, chars: "DINGOSKYdingosky", rand_bytes: &:rand.bytes/1)
    )

    hex_puid = fn -> for(_ <- 1..trials, do: HexPrngPuid128.generate()) end
    custom_puid = fn -> for(_ <- 1..trials, do: CustomPrngPuid128.generate()) end

    IO.puts("")
    time(hex_puid, "    Puid PRNG   ")
    time(custom_puid, "    Puid CSPRNG ")
  end

  @tag :uuid
  test "compare to uuid" do
    trials = 500_000

    IO.puts("\n--- UUID ---")

    IO.puts("\n  Generate #{trials} random IDs")

    defmodule(HexPuid, do: use(Puid, chars: :hex))

    uuid = fn -> for(_ <- 1..trials, do: UUID.uuid4()) end
    puid = fn -> for(_ <- 1..trials, do: HexPuid.generate()) end

    IO.puts("")
    time(uuid, "    UUID (122 bits) ")
    time(puid, "    Puid (128 bits) ")
  end

  @tag :utf8
  test "ascii vs utf8 encoding" do
    trials = 500_000

    IO.puts("\n--- ASCII vs UTF-8 ---")

    IO.puts("\n  Generate #{trials} random IDs")

    defmodule(AsciiPuid, do: use(Puid, chars: 'dingoskyDINGOSKY'))
    defmodule(Utf8Puid, do: use(Puid, chars: 'dîñgøskyDÎNGØSK¥'))

    ascii = fn -> for(_ <- 1..trials, do: AsciiPuid.generate()) end
    utf8 = fn -> for(_ <- 1..trials, do: Utf8Puid.generate()) end

    IO.puts("")
    time(ascii, "    ASCII")
    time(utf8, "    UTF-8")
  end
end
