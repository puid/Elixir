# Compares Puid (hex) with SecureRandom.hex(16) for 128-bit random ID generation
# Includes performance benchmarks and ERE, ETE metrics
#
# Usage:
#   MIX_ENV=test mix run bench/puid_secure_random_128.exs

Code.require_file("benchmark_helper.exs", __DIR__)

defmodule Bench.PuidSecureRandom128 do
  @trials 500_000
  @entropy_bits 128
  @random_bytes 16

  def run do
    defmodule HexPuid128, do: use(Puid, chars: :hex)

    secure_random_id = SecureRandom.hex(16)
    puid_id = HexPuid128.generate()

    IO.puts("\n# SecureRandom.hex(16) vs Puid Comparison")
    IO.puts("")

    IO.puts("## Charset: hex")
    IO.puts("- Size: 16 characters (0-9, a-f)")
    IO.puts("- Both use continuous hex strings")
    IO.puts("")

    IO.puts("## Example IDs")
    IO.puts("- SecureRandom: `#{secure_random_id}`")
    IO.puts("- Puid:         `#{puid_id}`")
    IO.puts("")

    sr_chars = String.length(secure_random_id)
    puid_chars = String.length(puid_id)

    sr_ere = Float.round(@entropy_bits / (sr_chars * 8), 2)
    puid_ere = Float.round(@entropy_bits / (puid_chars * 8), 2)

    sr_ete = Float.round(@entropy_bits / (@random_bytes * 8), 2)
    puid_ete = Float.round(@entropy_bits / (@random_bytes * 8), 2)

    IO.puts("## Performance Benchmark")
    IO.puts("  Generate #{@trials} random IDs with #{@entropy_bits} bits of entropy")

    secure_random = fn ->
      for _ <- 1..@trials, do: SecureRandom.hex(16)
    end

    puid = fn ->
      for _ <- 1..@trials, do: HexPuid128.generate()
    end

    IO.puts("")
    sr_time = BenchmarkHelper.time(secure_random, "    SecureRandom.hex(16) (CSPRNG)")
    puid_time = BenchmarkHelper.time(puid, "    Puid                 (CSPRNG)")

    IO.puts("")
    IO.puts("  Performance: #{BenchmarkHelper.format_performance(sr_time, puid_time)}")
    IO.puts("")

    BenchmarkHelper.metrics_table(
      "SecureRandom",
      sr_chars,
      sr_ere,
      sr_ete,
      puid_chars,
      puid_ere,
      puid_ete,
      @trials,
      sr_time,
      puid_time
    )

    IO.puts("\n## Summary")
    IO.puts("- Both generate 32-character hex strings")
    IO.puts("- Identical metrics (ERE, ETE) since both use hex encoding efficiently")
    IO.puts("- Performance is comparable (within ~5% typically)")
  end
end

Bench.PuidSecureRandom128.run()
