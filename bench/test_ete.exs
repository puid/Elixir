# Tests the theoretical ETE calculation by running trials and measuring actual bit consumption
#
# Usage:
#   mix run bench/test_ete.exs [charset] [trials]
#
# Example:
#   mix run bench/test_ete.exs decimal 1000000
#   mix run bench/test_ete.exs alphanum_lower

defmodule ETETest do
  @default_trials 1_000_000
  @bits 64

  def run(args) do
    {charset, trials} = parse_args(args)

    IO.puts("\nEmpirical ETE Test")
    IO.puts("=" |> String.duplicate(60))
    IO.puts("Charset: :#{charset}")
    IO.puts("Trials: #{trials}")
    IO.puts("Bits per ID: #{@bits}")
    IO.puts("")

    chars = Puid.Chars.charlist!(charset)
    charset_size = length(chars)
    theoretical_bits = :math.log2(charset_size)
    bits_per_char = Puid.Util.log_ceil(charset_size)
    bit_shifts = Puid.Bits.bit_shifts(charset_size)

    IO.puts("Charset size: #{charset_size}")
    IO.puts("Theoretical bits per char: #{Float.round(theoretical_bits, 2)}")
    IO.puts("Slice bits per char: #{bits_per_char}")
    IO.puts("Power of 2: #{Puid.Util.pow2?(charset_size)}")
    IO.puts("")

    ete_result = Puid.Chars.ete(charset)
    puid_ete = ete_result.ete
    naive_ete = calculate_naive_ete(charset_size, theoretical_bits, bits_per_char)

    IO.puts("Puid ETE: #{Float.round(puid_ete, 4)}")
    IO.puts("Naive ETE: #{Float.round(naive_ete, 4)}")

    if puid_ete != naive_ete do
      improvement = (puid_ete / naive_ete - 1) * 100
      IO.puts("Puid improvement: #{Float.round(improvement, 1)}%")
    end

    IO.puts("")

    {:ok, counter_agent} = Agent.start_link(fn -> 0 end)

    rand_module_name = String.to_atom("ETETestRand_#{charset}")

    if Code.ensure_loaded?(rand_module_name) do
      :code.purge(rand_module_name)
      :code.delete(rand_module_name)
    end

    Module.create(
      rand_module_name,
      quote do
        def rand_bytes(byte_count) do
          Agent.update(unquote(counter_agent), &(&1 + byte_count * 8))
          :crypto.strong_rand_bytes(byte_count)
        end
      end,
      Macro.Env.location(__ENV__)
    )

    module_name = String.to_atom("ETETest_#{charset}")

    if Code.ensure_loaded?(module_name) do
      :code.purge(module_name)
      :code.delete(module_name)
    end

    Module.create(
      module_name,
      quote do
        use Puid,
          bits: unquote(@bits),
          chars: unquote(charset),
          rand_bytes: &unquote(rand_module_name).rand_bytes/1
      end,
      Macro.Env.location(__ENV__)
    )

    info = apply(module_name, :info, [])
    id_length = info.length
    total_id_bits = id_length * theoretical_bits

    IO.puts("ID length: #{id_length} characters")
    IO.puts("Total ID entropy: #{Float.round(total_id_bits, 2)} bits")
    IO.puts("")

    Agent.update(counter_agent, fn _ -> 0 end)

    IO.puts("Running #{trials} trials...")
    start_time = System.monotonic_time(:millisecond)

    for _ <- 1..trials do
      apply(module_name, :generate, [])
    end

    elapsed_ms = System.monotonic_time(:millisecond) - start_time

    total_bits_consumed = Agent.get(counter_agent, & &1)
    Agent.stop(counter_agent)

    avg_bits_per_id = total_bits_consumed / trials
    empirical_ete = total_id_bits / avg_bits_per_id

    IO.puts("Done in #{elapsed_ms}ms")
    IO.puts("")
    IO.puts("Results:")
    IO.puts("-" |> String.duplicate(40))
    IO.puts("Total IDs generated: #{trials}")
    IO.puts("Total bits consumed: #{total_bits_consumed}")
    IO.puts("Average bits per ID: #{Float.round(avg_bits_per_id, 2)}")
    IO.puts("Expected bits per ID (Puid): #{Float.round(total_id_bits / puid_ete, 2)}")
    IO.puts("Expected bits per ID (Naive): #{Float.round(total_id_bits / naive_ete, 2)}")
    IO.puts("")
    IO.puts("Empirical ETE: #{Float.round(empirical_ete, 4)}")
    IO.puts("Puid ETE: #{Float.round(puid_ete, 4)}")
    IO.puts("Naive ETE: #{Float.round(naive_ete, 4)}")
    IO.puts("Difference from Puid: #{Float.round((empirical_ete - puid_ete) * 100, 2)}%")
    IO.puts("")

    if abs(empirical_ete - puid_ete) < 0.01 do
      IO.puts("✓ Empirical and calculated Puid ETE match closely!")
    else
      IO.puts("⚠ Significant difference between empirical and calculated ETE")
      IO.puts("  This might indicate an issue with the ETE calculation")
    end

    if puid_ete != naive_ete do
      actual_improvement = (empirical_ete / naive_ete - 1) * 100
      IO.puts("")
      IO.puts("Puid vs Naive Comparison:")
      IO.puts("-" |> String.duplicate(40))
      IO.puts("Empirical improvement over naive: #{Float.round(actual_improvement, 1)}%")

      naive_bits_needed = total_id_bits / naive_ete * trials
      extra_bits = naive_bits_needed - total_bits_consumed
      IO.puts("Extra bits naive would consume: #{Float.round(extra_bits, 0)}")
      IO.puts("That's #{Float.round(extra_bits / 8, 0)} extra bytes for #{trials} IDs")
    end

    if not Puid.Util.pow2?(charset_size) do
      IO.puts("")
      IO.puts("Efficiency Analysis:")
      IO.puts("-" |> String.duplicate(40))

      perfect_bits = trials * id_length * theoretical_bits
      wasted_bits = total_bits_consumed - perfect_bits
      waste_percent = wasted_bits / total_bits_consumed * 100

      IO.puts("Perfect world bits needed: #{Float.round(perfect_bits, 0)}")
      IO.puts("Actual bits consumed: #{total_bits_consumed}")
      IO.puts("Bits wasted on rejections: #{Float.round(wasted_bits, 0)}")
      IO.puts("Waste percentage: #{Float.round(waste_percent, 2)}%")
    end
  end

  defp parse_args([]), do: parse_args(["alphanum_lower"])
  defp parse_args([charset]), do: {String.to_atom(charset), @default_trials}

  defp parse_args([charset, trials]) do
    {String.to_atom(charset), String.to_integer(trials)}
  end

  defp parse_args(_) do
    IO.puts("Usage: mix run bench/test_ete.exs [charset] [trials]")
    System.halt(1)
  end

  defp calculate_naive_ete(charset_size, theoretical_bits, bits_per_char) do
    if Puid.Util.pow2?(charset_size) do
      1.0
    else
      total_values = Puid.Util.pow2(bits_per_char)
      p_accept = charset_size / total_values
      expected_attempts = 1 / p_accept
      expected_bits = expected_attempts * bits_per_char
      theoretical_bits / expected_bits
    end
  end
end

ETETest.run(System.argv())
