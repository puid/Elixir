# Compares Puid with a naive random ID generation solution
# Includes performance benchmarks and ERE, ETE, ECE metrics
#
# Usage:
#   MIX_ENV=test mix run bench/puid_naive.exs

Code.require_file("benchmark_helper.exs", __DIR__)

defmodule Bench.PuidNaive do
  @trials 500_000
  @entropy_bits 128
  @bits_per_char 5

  def run do
    defmodule PuidBase32Hex do
      # Use PRNG instead of default CSPRNG
      use Puid, chars: :base32_hex, rand_bytes: &:rand.bytes/1
    end

    puid_info = PuidBase32Hex.info()
    puid_chars_len = puid_info.length
    puid_charset = puid_info.characters

    naive_solution = fn len, chars ->
      chars_list = String.graphemes(chars)

      1..len
      |> Enum.map(fn _ -> Enum.random(chars_list) end)
      |> Enum.join()
    end

    :rand.seed(:exsss)
    naive_id = naive_solution.(puid_chars_len, puid_charset)
    puid_id = PuidBase32Hex.generate()

    IO.puts("\n# Naive Solution vs Puid Comparison")
    IO.puts("")

    IO.puts("## Charset: base32_hex")
    IO.puts("- Size: 32 characters (0-9, a-v)")
    IO.puts("- Naive Solution: #{puid_chars_len} characters using custom chars")
    IO.puts("- Puid: #{puid_chars_len} characters using :base32_hex")
    IO.puts("")

    IO.puts("## Example IDs")
    IO.puts("- Naive Solution: `#{naive_id}`")
    IO.puts("- Puid:           `#{puid_id}`")
    IO.puts("")

    naive_random_bits = puid_chars_len * 64
    naive_random_bytes = naive_random_bits / 8

    puid_actual_bits = puid_chars_len * @bits_per_char
    puid_random_bytes = puid_actual_bits / 8

    naive_ere = Float.round(@entropy_bits / (puid_chars_len * 8), 2)
    puid_ere = Float.round(puid_info.entropy_bits / (puid_chars_len * 8), 2)

    naive_ete = Float.round(@bits_per_char / 64, 2)
    puid_ete = 1.0

    IO.puts("## Performance Benchmark")
    IO.puts("  Generate #{@trials} random IDs with #{@entropy_bits} bits of entropy")

    naive = fn ->
      for _ <- 1..@trials, do: naive_solution.(puid_chars_len, puid_charset)
    end

    puid = fn ->
      for _ <- 1..@trials, do: PuidBase32Hex.generate()
    end

    IO.puts("")

    :rand.seed(:exsss)
    naive_time = BenchmarkHelper.time(naive, "    Naive Solution (PRNG)")

    :rand.seed(:exsss)
    puid_time = BenchmarkHelper.time(puid, "    Puid           (PRNG)")

    IO.puts("")
    IO.puts("  Performance: #{BenchmarkHelper.format_performance(naive_time, puid_time)}")
    IO.puts("")

    BenchmarkHelper.metrics_table(
      "Naive",
      puid_chars_len,
      naive_ere,
      naive_ete,
      puid_chars_len,
      puid_ere,
      puid_ete,
      @trials,
      naive_time,
      puid_time
    )

    IO.puts("\n## Detailed Analysis")
    IO.puts("")
    IO.puts("### Naive Solution Characteristics")
    IO.puts("- Algorithm: Pick random character from charset for each position")

    IO.puts(
      "- Random calls: #{puid_chars_len} calls to Enum.random (uses :rand.uniform internally)"
    )

    IO.puts("- Bits per call: 64 bits (Erlang's PRNG internal state)")
    IO.puts("- Total random bits used: #{trunc(naive_random_bits)} bits")
    IO.puts("- Random bytes consumed: #{trunc(naive_random_bytes)} bytes")
    IO.puts("- Waste: Uses 64 bits to select from 32 choices (5 bits needed)")
    IO.puts("")

    IO.puts("### Puid Characteristics")
    IO.puts("- Algorithm: Efficient bit-slicing from random byte stream")
    IO.puts("- Random bytes consumed: ~#{Float.round(puid_random_bytes, 1)} bytes")
    IO.puts("- Efficiency: 100% for 32-character set (power-of-2)")
    IO.puts("- Configured to use PRNG for this comparison (uses CSPRNG by default)")
    IO.puts("")

    IO.puts("\n## Summary")
    IO.puts("- Both generate #{puid_chars_len}-character IDs with base32_hex charset")

    IO.puts(
      "- Naive solution uses #{trunc(naive_random_bytes)} bytes vs Puid's ~#{Float.round(puid_random_bytes, 1)} bytes"
    )

    IO.puts(
      "- Naive solution wastes ~#{Float.round((1 - puid_random_bytes / naive_random_bytes) * 100, 0)}% of random bytes"
    )

    IO.puts("- Puid's ETE is #{Float.round(puid_ete / naive_ete, 1)}x better")
    IO.puts("- Both use PRNG in this comparison for fairness")
    IO.puts("- Note: Puid uses CSPRNG by default, but configured to use PRNG here")
    IO.puts("- Common mistake: Naive solution seems simple but is highly inefficient")
  end
end

Bench.PuidNaive.run()
