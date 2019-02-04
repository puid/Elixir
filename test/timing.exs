defmodule TimingTest do
  use ExUnit.Case

  defmodule(AlphanumPuid128, do: use(Puid, charset: :alphanum))
  defmodule(DingoskyPuid64, do: use(Puid, bits: 64, chars: "dingosky"))
  defmodule(PrintablePuid128, do: use(Puid, charset: :printable_ascii))
  defmodule(UpperAlphanumPuid31, do: use(Puid, bits: 31, charset: :alphanum_upper))
  defmodule(Safe64Puid128, do: use(Puid, charset: :safe64))
  defmodule(UnicodePuid64, do: use(Puid, bits: 92, chars: "ŮήιƈŏδεĊħąŕαсτəř"))

  def time(function, label) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
    |> IO.inspect(label: label)
  end

  def common_solution(len, chars) do
    char_count = chars |> String.length()

    for(_ <- 1..len, do: :rand.uniform(char_count) - 1)
    |> Enum.map(&(chars |> String.at(&1)))
    |> List.to_string()
  end

  @tag :common_solution
  test "compare to common solution custom 8 chars" do
    trials = 50_000

    chars = DingoskyPuid64.info().chars
    len = DingoskyPuid64.info().length
    common = fn -> for(_ <- 1..trials, do: common_solution(len, chars)) end
    puid = fn -> for(_ <- 1..trials, do: DingoskyPuid64.generate()) end

    IO.puts("\nGenerate #{trials} random IDs with 128 bits of entropy using 8 custom characters")

    :rand.seed(:exsp)
    time(common, "  Common Solution   (PRNG) ")
    :crypto.rand_seed()
    time(common, "  Common Solution (CSPRNG) ")
    time(puid, "  Puid            (CSPRNG) ")
  end

  @tag :common_solution
  test "compare to common solution (alphanum)" do
    trials = 50_000

    chars = AlphanumPuid128.info().chars
    len = AlphanumPuid128.info().length
    common = fn -> for(_ <- 1..trials, do: common_solution(len, chars)) end
    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128.generate()) end

    IO.puts(
      "\nGenerate #{trials} random IDs with 128 bits of entropy using #{:alphanum} characters"
    )

    :rand.seed(:exsp)
    time(common, "  Common Solution   (PRNG) ")
    :crypto.rand_seed()
    time(common, "  Common Solution (CSPRNG) ")
    time(puid, "  Puid            (CSPRNG) ")
  end

  @tag :common_solution
  test "compare to common solution (unicode)" do
    trials = 50_000

    chars = UnicodePuid64.info().chars
    len = UnicodePuid64.info().length
    common = fn -> for(_ <- 1..trials, do: common_solution(len, chars)) end
    puid = fn -> for(_ <- 1..trials, do: UnicodePuid64.generate()) end

    n_chars = chars |> String.length()

    IO.puts(
      "\nGenerate #{trials} random IDs with 92 bits of entropy using #{n_chars} unicode characters"
    )

    :rand.seed(:exsp)
    time(common, "  Common Solution   (PRNG) ")
    :crypto.rand_seed()
    time(common, "  Common Solution (CSPRNG) ")
    time(puid, "  Puid            (CSPRNG) ")
  end

  @tag :entropy_string
  test "compare to :entropy_string using safe64 chars" do
    trials = 100_000

    IO.puts(
      "\nGenerate #{trials} random IDs with 128 bits of entropy using #{:safe64} characters"
    )

    defmodule(ES128, do: use(EntropyString, bits: 128, charset: :charset64))

    entropy_string = fn -> for(_ <- 1..trials, do: ES128.random()) end
    puid = fn -> for(_ <- 1..trials, do: Safe64Puid128.generate()) end

    time(entropy_string, "  Entropy String (CSPRNG) ")
    time(puid, "  Puid           (CSPRNG) ")
  end

  @tag :entropy_string
  test "compare to :entropy_string using custom chars" do
    trials = 100_000
    chars = DingoskyPuid64.info().chars

    defmodule(CustomES64, do: use(EntropyString, bits: 64, charset: chars))

    IO.puts(
      "\nGenerate #{trials} random IDs with 64 bits of entropy using #{String.length(chars)} custom characters"
    )

    entropy_string = fn -> for(_ <- 1..trials, do: CustomES64.random()) end
    puid = fn -> for(_ <- 1..trials, do: DingoskyPuid64.generate()) end

    time(entropy_string, "  Entropy String (CSPRNG) ")
    time(puid, "  Puid           (CSPRNG) ")
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

    IO.puts(
      "\nGenerate #{trials} random IDs with 31 bits of entropy using #{:alphanum_upper} characters"
    )

    gen_reference = fn -> for(_ <- 1..trials, do: gen_reference()) end
    puid = fn -> for(_ <- 1..trials, do: UpperAlphanumPuid31.generate()) end

    :rand.seed(:exsp)
    time(gen_reference, "  gen_reference   (PRNG) ")
    :crypto.rand_seed()
    time(gen_reference, "  gen_reference (CSPRNG) ")
    time(puid, "  Puid          (CSPRNG) ")
  end

  @tag :misc_random
  test "compare to Misc.Random alphanum" do
    trials = 50_000

    IO.puts(
      "\nGenerate #{trials} random IDs with 128 bits of entropy using #{:alphanum} characters"
    )

    misc_random = fn -> for(_ <- 1..trials, do: Misc.Random.get_string(22)) end
    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128.generate()) end

    time(misc_random, "  Misc.Random (PRNG) ")
    time(puid, "  Puid      (CSPRNG) ")
  end

  @tag :not_qwerty123
  test "compare to NotQwert123 alphanum" do
    trials = 50_000

    IO.puts(
      "\nGenerate #{trials} random IDs with 128 bits of entropy using #{:alphanum} characters"
    )

    not_querty_alphanum = fn ->
      for(_ <- 1..trials, do: NotQwerty123.RandomPassword.gen_password(length: 22))
    end

    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128.generate()) end

    time(not_querty_alphanum, "  NotQwerty123 (CSPRNG) ")
    time(puid, "  Puid         (CSPRNG) ")
  end

  @tag :not_qwerty123
  test "compare to NotQwert123 printable" do
    trials = 50_000

    IO.puts(
      "\nGenerate #{trials} random IDs with 128 bits of entropy using #{:printable_ascii} characters"
    )

    not_querty_printable = fn ->
      for(
        _ <- 1..trials,
        do: NotQwerty123.RandomPassword.gen_password(length: 20, characters: :letters_digits_punc)
      )
    end

    puid = fn -> for(_ <- 1..trials, do: PrintablePuid128.generate()) end

    time(not_querty_printable, "  NotQwerty123 (CSPRNG) ")
    time(puid, "  Puid         (CSPRNG) ")
  end

  @tag :randomizer
  test "compare to Randomizer" do
    trials = 5_000

    IO.puts(
      "\nGenerate #{trials} random IDs with 128 bits of entropy using #{:alphanum} characters"
    )

    randomizer = fn -> for(_ <- 1..trials, do: Randomizer.generate!(22)) end
    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128.generate()) end

    :rand.seed(:exsp)
    time(randomizer, "  Randomizer   (PRNG) ")
    :crypto.rand_seed()
    time(randomizer, "  Randomizer (CSPRNG) ")

    time(puid, "  Puid       (CSPRNG) ")
  end

  @tag :rand_str
  test "compare to :rand_str using safe64 chars" do
    trials = 100_000

    IO.puts(
      "\nGenerate #{trials} random IDs with 128 bits of entropy using #{:safe64} characters"
    )

    rand_str = fn -> for(_ <- 1..trials, do: :rand_str.get(22)) end
    puid = fn -> for(_ <- 1..trials, do: Safe64Puid128.generate()) end

    :rand.seed(:exsp)
    time(rand_str, "  :rand_str   (PRNG) ")
    :crypto.rand_seed()
    time(rand_str, "  :rand_str (CSPRNG) ")
    time(puid, "  Puid      (CSPRNG) ")
  end

  @tag :rand_str
  test "compare to :rand_str using alphanum" do
    trials = 100_000

    IO.puts("\nGenerate #{trials} random IDs with 128 bits of entropy using alphanum characters")

    alphanum = AlphanumPuid128.info().chars |> to_charlist()
    rand_str = fn -> for(_ <- 1..trials, do: :rand_str.get(22, alphanum)) end
    puid = fn -> for(_ <- 1..trials, do: AlphanumPuid128.generate()) end

    :rand.seed(:exsp)
    time(rand_str, "  :rand_str   (PRNG) ")
    :crypto.rand_seed()
    time(rand_str, "  :rand_str (CSPRNG) ")
    time(puid, "  Puid      (CSPRNG) ")
  end

  @tag :secure_random
  test "compare to SecureRandom safe64" do
    trials = 500_000

    IO.puts(
      "\nGenerate #{trials} random IDs with 128 bits of entropy using #{:safe64} characters"
    )

    secure_random = fn -> for(_ <- 1..trials, do: SecureRandom.urlsafe_base64()) end
    puid = fn -> for(_ <- 1..trials, do: Safe64Puid128.generate()) end

    time(secure_random, "  SecureRandom (CSPRNG) ")
    time(puid, "  Puid         (CSPRNG) ")
  end

  @tag :secure_random
  test "compare to SecureRandom hex" do
    trials = 500_000

    IO.puts("\nGenerate #{trials} random IDs with 128 bits of entropy using #{:hex} characters")

    defmodule(HexPuid128, do: use(Puid, charset: :hex))
    
    secure_random = fn -> for(_ <- 1..trials, do: SecureRandom.hex(16)) end
    puid = fn -> for(_ <- 1..trials, do: HexPuid128.generate()) end

    time(secure_random, "  SecureRandom (CSPRNG) ")
    time(puid, "  Puid         (CSPRNG) ")
  end

  @tag :uuid
  test "compare to uuid" do
    trials = 500_000

    IO.puts("\nGenerate #{trials} random IDs with 122 bits of entropy using #{:hex}")

    defmodule(HexPuid122, do: use(Puid, bits: 122, charset: :hex))
    
    uuid = fn -> for(_ <- 1..trials, do: UUID.uuid4()) end
    puid = fn -> for(_ <- 1..trials, do: HexPuid122.generate()) end

    time(uuid, "  UUID         ")
    time(puid, "  Puid hex     ")

    IO.puts("\nGenerate #{trials} random IDs with 122 bits of entropy using #{:safe64}")
    
    defmodule(Safe64Puid122, do: use(Puid, bits: 122, charset: :safe64))
    safe = fn -> for(_ <- 1..trials, do: Safe64Puid122.generate()) end

    time(uuid, "  UUID         ")
    time(safe, "  Puid :safe64 ")
    
  end
  
  @tag :puid
  test "increasing custom char counts" do
    trials = 25_000

    IO.puts(
      "\nGenerate #{trials} random IDs with 92 bits of entropy and increasing custom " <>
        "ascii character counts"
    )

    def_puid_mod = fn chars ->
      count = chars |> String.length()
      name = "Puid_Custom_#{count}" |> String.to_atom()
      defmodule(name, do: use(Puid, bits: 92, chars: chars))
      name
    end

    3..36
    |> Enum.map(&(AlphanumPuid128.info().chars |> String.slice(0, &1) |> def_puid_mod.()))
    |> Enum.map(fn mod -> {mod, fn -> for(_ <- 1..trials, do: mod.generate()) end} end)
    |> Enum.each(fn {mod, puid_fn} -> time(puid_fn, "  #{mod} ") end)
  end
end
