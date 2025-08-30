# Compares Puid with Misc.Random for random ID generation
# Includes performance benchmarks and ERE, ETE metrics
#
# Usage:
#   MIX_ENV=test mix run bench/puid_misc_random.exs

Code.require_file("benchmark_helper.exs", __DIR__)

defmodule Bench.PuidMiscRandom do
  @trials 500_000
  @misc_random_chars 22
  @bits_per_char :math.log2(62)
  @entropy_bits 128

  @misc_random_bytes 176

  def run do
    defmodule PuidAlphanum do
      use Puid, bits: 128, chars: :alphanum
    end

    info = PuidAlphanum.info()
    puid_chars = info.length

    puid_actual_bits = puid_chars * 6 / 0.97
    puid_random_bytes = Float.round(puid_actual_bits / 8, 1)

    misc_random_id = Misc.Random.string(22)
    puid_id = PuidAlphanum.generate()

    IO.puts("\n# Misc.Random vs Puid Comparison")
    IO.puts("")

    IO.puts("## Charset: alphanum")
    IO.puts("- Size: 62 characters (A-Za-z0-9)")
    IO.puts("- Misc.Random: 22 characters for 128 bits")
    IO.puts("- Puid: #{puid_chars} characters for 128 bits")
    IO.puts("")

    IO.puts("## Example IDs")
    IO.puts("- Misc.Random: `#{misc_random_id}`")
    IO.puts("- Puid:        `#{puid_id}`")
    IO.puts("")

    misc_random_chars_len = String.length(misc_random_id)
    puid_chars_len = String.length(puid_id)

    misc_random_ere = Float.round(@entropy_bits / (misc_random_chars_len * 8), 2)
    puid_ere = Float.round(info.entropy_bits / (puid_chars_len * 8), 2)

    # ETE (Entropy Transform Efficiency)
    # For Misc.Random: uses :rand.uniform for each character
    # Each character selection uses full 64 bits from PRNG
    misc_random_avg_bits_per_char = @misc_random_bytes * 8 / @misc_random_chars
    misc_random_ete = Float.round(@bits_per_char / misc_random_avg_bits_per_char, 2)

    puid_ete = Float.round(0.97, 2)

    IO.puts("## Performance Benchmark")
    IO.puts("  Generate #{@trials} random IDs with #{@entropy_bits} bits of entropy")

    misc_random = fn ->
      for _ <- 1..@trials, do: Misc.Random.string(22)
    end

    puid = fn ->
      for _ <- 1..@trials, do: PuidAlphanum.generate()
    end

    IO.puts("")

    :rand.seed(:exsss)
    misc_random_time = BenchmarkHelper.time(misc_random, "    Misc.Random (PRNG by default)")

    puid_time = BenchmarkHelper.time(puid, "    Puid        (CSPRNG)")

    IO.puts("")
    IO.puts("  Performance: #{BenchmarkHelper.format_performance(misc_random_time, puid_time)}")
    IO.puts("")

    BenchmarkHelper.metrics_table(
      "Misc.Random",
      misc_random_chars_len,
      misc_random_ere,
      misc_random_ete,
      puid_chars_len,
      puid_ere,
      puid_ete,
      @trials,
      misc_random_time,
      puid_time
    )

    IO.puts("\n## Summary")
    IO.puts("- Both use alphanum charset (62 characters)")
    IO.puts("- Both generate #{@misc_random_chars}-character IDs")
    IO.puts("- Puid's ETE is #{Float.round(puid_ete / misc_random_ete, 1)}x better")

    IO.puts(
      "- Misc.Random uses ~#{@misc_random_bytes} bytes vs Puid's ~#{puid_random_bytes} bytes"
    )

    IO.puts("- Misc.Random uses Erlang's :rand module (PRNG, not cryptographically secure)")
    IO.puts("- Puid uses :crypto.strong_rand_bytes (CSPRNG) by default")
    IO.puts("- Note: Misc.Random can be configured to use CSPRNG with :crypto.rand_seed()")
  end
end

Bench.PuidMiscRandom.run()
