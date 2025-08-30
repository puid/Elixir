# Compares Puid with Nanoid for random ID generation
# Includes performance benchmarks and ERE, ETE metrics
#
# Usage:
#   MIX_ENV=test mix run bench/puid_nanoid.exs

Code.require_file("benchmark_helper.exs", __DIR__)

defmodule Bench.PuidNanoid do
  @trials 500_000
  @entropy_bits 126
  @nanoid_random_bytes 34
  @puid_random_bytes 16

  def run do
    defmodule PuidSafe64 do
      use Puid, bits: 126, chars: :safe64
    end

    nanoid_id = Nanoid.generate()
    puid_id = PuidSafe64.generate()

    IO.puts("\n# Nanoid vs Puid Comparison")
    IO.puts("")

    IO.puts("## Charset: safe64")
    IO.puts("- Size: 64 characters (A-Za-z0-9-_)")
    IO.puts("- URL-safe base64 variant")
    IO.puts("- Both libraries use the same 21-character length by default")
    IO.puts("")

    IO.puts("## Example IDs")
    IO.puts("- Nanoid: `#{nanoid_id}`")
    IO.puts("- Puid:   `#{puid_id}`")
    IO.puts("")

    charset_size = 64
    bits_per_char = :math.log2(charset_size)

    nanoid_chars = String.length(nanoid_id)
    puid_chars = String.length(puid_id)

    nanoid_ere = Float.round(@entropy_bits / (nanoid_chars * 8), 2)
    puid_ere = Float.round(@entropy_bits / (puid_chars * 8), 2)

    nanoid_avg_bits_per_char = @nanoid_random_bytes * 8 / 21
    nanoid_ete = Float.round(bits_per_char / nanoid_avg_bits_per_char, 2)

    puid_avg_bits_per_char = bits_per_char
    puid_ete = Float.round(bits_per_char / puid_avg_bits_per_char, 2)

    IO.puts("## Performance Benchmark")
    IO.puts("  Generate #{@trials} random IDs with #{@entropy_bits} bits of entropy")

    nanoid = fn ->
      for _ <- 1..@trials, do: Nanoid.generate()
    end

    puid = fn ->
      for _ <- 1..@trials, do: PuidSafe64.generate()
    end

    IO.puts("")
    nanoid_time = BenchmarkHelper.time(nanoid, "    Nanoid (CSPRNG)")
    puid_time = BenchmarkHelper.time(puid, "    Puid   (CSPRNG)")

    IO.puts("")
    IO.puts("  Performance: #{BenchmarkHelper.format_performance(nanoid_time, puid_time)}")
    IO.puts("")

    BenchmarkHelper.metrics_table(
      "Nanoid",
      nanoid_chars,
      nanoid_ere,
      nanoid_ete,
      puid_chars,
      puid_ere,
      puid_ete,
      @trials,
      nanoid_time,
      puid_time
    )

    IO.puts("\n## Summary")
    IO.puts("- Both generate 21-character IDs with safe64 charset")

    IO.puts(
      "- Puid's ETE is #{Float.round(puid_ete / nanoid_ete, 2)}x better (no rejection sampling waste)"
    )

    IO.puts(
      "- Puid uses #{Float.round((1 - @puid_random_bytes / @nanoid_random_bytes) * 100, 0)}% fewer random bytes"
    )

    IO.puts("- Nanoid uses rejection sampling which wastes ~53% of random bytes")
  end
end

Bench.PuidNanoid.run()
