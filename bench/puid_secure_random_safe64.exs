# Compares default Puid (safe64) with SecureRandom.urlsafe_base64 for 128-bit random ID generation
# Includes performance benchmarks and ERE, ETE metrics
#
# Usage:
#   MIX_ENV=test mix run bench/puid_secure_random_safe64.exs

Code.require_file("benchmark_helper.exs", __DIR__)

defmodule Bench.PuidSecureRandomSafe64 do
  @trials 500_000
  @entropy_bits 128
  @random_bytes 16

  def run do
    defmodule DefaultPuid, do: use(Puid)

    secure_random_id = SecureRandom.urlsafe_base64(16)
    puid_id = DefaultPuid.generate()

    IO.puts("\n# SecureRandom.urlsafe_base64 vs Puid Comparison")
    IO.puts("")

    IO.puts("## Charset: safe64")
    IO.puts("- Size: 64 characters (A-Za-z0-9-_)")
    IO.puts("- URL-safe base64 encoding")
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
      for _ <- 1..@trials, do: SecureRandom.urlsafe_base64(16)
    end

    puid = fn ->
      for _ <- 1..@trials, do: DefaultPuid.generate()
    end

    IO.puts("")
    sr_time = BenchmarkHelper.time(secure_random, "    SecureRandom.urlsafe_base64(16) (CSPRNG)")
    puid_time = BenchmarkHelper.time(puid, "    Puid                            (CSPRNG)")

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
    IO.puts("- SecureRandom: #{sr_chars} characters (implementation produces longer output)")
    IO.puts("- Puid: #{puid_chars} characters (optimal for safe64 encoding)")
    IO.puts("- Puid's ERE is #{Float.round(puid_ere / sr_ere, 2)}x better")
    IO.puts("- Puid generates #{Float.round((1 - puid_chars / sr_chars) * 100, 0)}% shorter IDs")
  end
end

Bench.PuidSecureRandomSafe64.run()
