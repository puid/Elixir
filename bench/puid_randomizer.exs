# Compares Puid with Randomizer for random ID generation
# Includes performance benchmarks and ERE, ETE metrics
#
# Usage:
#   MIX_ENV=test mix run bench/puid_randomizer.exs

Code.require_file("benchmark_helper.exs", __DIR__)

defmodule Bench.PuidRandomizer do
  @trials 500_000
  @randomizer_chars 10
  @bits_per_char :math.log2(62)
  # ~59.5 bits
  @entropy_bits @randomizer_chars * @bits_per_char
  @randomizer_random_bytes 80

  def run do
    defmodule PuidAlphanum do
      use Puid, bits: 59.5, chars: :alphanum
    end

    info = PuidAlphanum.info()
    puid_chars = info.length

    puid_actual_bits = puid_chars * 6 / 0.97
    puid_random_bytes = Float.round(puid_actual_bits / 8, 1)

    randomizer_id = Randomizer.generate!(10)
    puid_id = PuidAlphanum.generate()

    IO.puts("\n# Randomizer vs Puid Comparison")
    IO.puts("")

    IO.puts("## Charset: alphanum")
    IO.puts("- Size: 62 characters (A-Za-z0-9)")
    IO.puts("- Randomizer: 10 characters by default")
    IO.puts("- Puid: #{puid_chars} characters for equivalent entropy")
    IO.puts("")

    IO.puts("## Example IDs")
    IO.puts("- Randomizer: `#{randomizer_id}`")
    IO.puts("- Puid:       `#{puid_id}`")
    IO.puts("")

    randomizer_chars_len = String.length(randomizer_id)
    puid_chars_len = String.length(puid_id)

    randomizer_ere = Float.round(@entropy_bits / (randomizer_chars_len * 8), 2)
    puid_ere = Float.round(info.entropy_bits / (puid_chars_len * 8), 2)

    randomizer_avg_bits_per_char = @randomizer_random_bytes * 8 / @randomizer_chars
    randomizer_ete = Float.round(@bits_per_char / randomizer_avg_bits_per_char, 2)

    puid_ete = Float.round(0.97, 2)

    IO.puts("## Performance Benchmark")

    IO.puts(
      "  Generate #{@trials} random IDs with ~#{Float.round(@entropy_bits, 1)} bits of entropy"
    )

    # Define benchmark functions
    randomizer = fn ->
      for _ <- 1..@trials, do: Randomizer.generate!(10)
    end

    puid = fn ->
      for _ <- 1..@trials, do: PuidAlphanum.generate()
    end

    IO.puts("")
    randomizer_time = BenchmarkHelper.time(randomizer, "    Randomizer (PRNG after seeding)")
    puid_time = BenchmarkHelper.time(puid, "    Puid       (CSPRNG)")

    IO.puts("")
    IO.puts("  Performance: #{BenchmarkHelper.format_performance(randomizer_time, puid_time)}")
    IO.puts("")

    BenchmarkHelper.metrics_table(
      "Randomizer",
      randomizer_chars_len,
      randomizer_ere,
      randomizer_ete,
      puid_chars_len,
      puid_ere,
      puid_ete,
      @trials,
      randomizer_time,
      puid_time
    )

    IO.puts("\n## Summary")
    IO.puts("- Both use alphanum charset (62 characters)")
    IO.puts("- Puid's ETE is #{Float.round(puid_ete / randomizer_ete, 1)}x better")

    IO.puts(
      "- Randomizer uses ~#{@randomizer_random_bytes} bytes vs Puid's ~#{puid_random_bytes} bytes"
    )

    IO.puts("- Randomizer uses Enum.random (PRNG), not cryptographically secure by default")
    IO.puts("- Puid uses :crypto.strong_rand_bytes (CSPRNG) by default")
  end
end

Bench.PuidRandomizer.run()
