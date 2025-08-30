# Compares Puid with Elixir UUID module for UUID v4 generation
# Includes performance benchmarks and ERE, ETE metrics
#
# Usage:
#   MIX_ENV=test mix run bench/puid_uuid.exs

Code.require_file("benchmark_helper.exs", __DIR__)

defmodule Bench.PuidUuid do
  @trials 500_000
  @uuid_entropy_bits 122
  @uuid_bytes 16

  def run do
    defmodule PuidHex do
      use Puid, chars: :hex
    end

    puid_info = PuidHex.info()
    # This will be 128
    puid_entropy_bits = puid_info.entropy_bits

    uuid_id = UUID.uuid4()
    puid_id = PuidHex.generate()

    IO.puts("\n# Elixir UUID vs Puid Comparison")
    IO.puts("")

    IO.puts("## Charset: hex")
    IO.puts("- Size: 16 characters (0-9, a-f)")
    IO.puts("- Bits per character: 4")
    IO.puts("- UUID format: 8-4-4-4-12 (with dashes)")
    IO.puts("- Puid format: continuous hex string")
    IO.puts("")

    IO.puts("## Example IDs")
    IO.puts("- UUID v4 (122 bits):  `#{uuid_id}`")
    IO.puts("- Puid (#{trunc(puid_entropy_bits)} bits):     `#{puid_id}`")
    IO.puts("")

    uuid_chars = String.length(uuid_id)
    puid_chars = String.length(puid_id)

    uuid_ere = Float.round(@uuid_entropy_bits / (uuid_chars * 8), 2)
    puid_ere = Float.round(puid_entropy_bits / (puid_chars * 8), 2)

    uuid_ete = Float.round(@uuid_entropy_bits / (@uuid_bytes * 8), 2)
    puid_ete = 1.0

    IO.puts("## Performance Benchmark")
    IO.puts("  Generate #{@trials} random IDs")

    uuid_v4 = fn ->
      for _ <- 1..@trials, do: UUID.uuid4()
    end

    puid = fn ->
      for _ <- 1..@trials, do: PuidHex.generate()
    end

    IO.puts("")
    uuid_time = BenchmarkHelper.time(uuid_v4, "    UUID v4 (122 bits entropy, CSPRNG)")

    puid_time =
      BenchmarkHelper.time(puid, "    Puid    (#{trunc(puid_entropy_bits)} bits entropy, CSPRNG)")

    IO.puts("")
    IO.puts("  Performance: #{BenchmarkHelper.format_performance(uuid_time, puid_time)}")
    IO.puts("")

    BenchmarkHelper.metrics_table(
      "UUID v4",
      uuid_chars,
      uuid_ere,
      uuid_ete,
      puid_chars,
      puid_ere,
      puid_ete,
      @trials,
      uuid_time,
      puid_time
    )

    IO.puts("\n## Detailed Comparison")
    IO.puts("")
    IO.puts("### UUID v4 Characteristics")
    IO.puts("- Format: XXXXXXXX-XXXX-4XXX-YXXX-XXXXXXXXXXXX")
    IO.puts("- Total length: 36 characters (32 hex + 4 dashes)")
    IO.puts("- Entropy: 122 bits (6 bits used for version/variant)")
    IO.puts("- Random bytes used: 16")
    IO.puts("- Dashes: Add 4 characters with no entropy")
    IO.puts("")

    IO.puts("### Puid Characteristics")
    IO.puts("- Format: Continuous hex string")
    IO.puts("- Entropy: #{trunc(puid_entropy_bits)} bits")
    IO.puts("- Length: #{puid_chars} characters")
    IO.puts("- Random bytes used: #{div(trunc(puid_entropy_bits), 8)}")
    IO.puts("- No formatting overhead")
    IO.puts("")

    IO.puts("\n## Summary")
    IO.puts("- UUID v4: #{uuid_chars} characters with 122 bits entropy")
    IO.puts("- Puid: #{puid_chars} characters with #{trunc(puid_entropy_bits)} bits entropy")
    IO.puts("- Puid generates 128 bits of entropy vs UUID's 122 bits")
    IO.puts("- Puid's ERE is #{Float.round(puid_ere / uuid_ere, 2)}x better than UUID")

    IO.puts(
      "- Puid generates #{Float.round((1 - puid_chars / uuid_chars) * 100, 0)}% shorter IDs than UUID"
    )

    IO.puts("- UUID format wastes 32 bits on dashes that carry no entropy")
    IO.puts("- UUID wastes 6 bits on version/variant fields")
    IO.puts("- Puid provides #{trunc(puid_entropy_bits) - 122} more bits of entropy than UUID v4")
    IO.puts("- Both use CSPRNG for secure random generation")
  end
end

Bench.PuidUuid.run()
