# Detailed ETE Analysis for :alphanum_lower charset
# Shows exactly how the bit-slicing algorithm works for 36 characters

charset = :alphanum_lower
chars = Puid.Chars.charlist!(charset)
charset_size = length(chars)
theoretical_bits = :math.log2(charset_size)
bits_per_char = Puid.Util.log_ceil(charset_size)
bit_shifts = Puid.Bits.bit_shifts(charset_size)

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("DETAILED ETE ANALYSIS: :alphanum_lower")
IO.puts(String.duplicate("=", 70))

IO.puts("\n## Charset Properties")
IO.puts(String.duplicate("-", 40))
IO.puts("Charset: :#{charset}")
IO.puts("Characters: #{chars}")
IO.puts("Charset size: #{charset_size} characters")
IO.puts("Theoretical bits per char: #{Float.round(theoretical_bits, 4)} bits")
IO.puts("Actual bits sliced: #{bits_per_char} bits")
IO.puts("Possible values with #{bits_per_char} bits: 0-#{Puid.Util.pow2(bits_per_char) - 1}")

IO.puts("\n## Bit Slicing Algorithm")
IO.puts(String.duplicate("-", 40))

IO.puts(
  "When we slice #{bits_per_char} bits, we get values 0-#{Puid.Util.pow2(bits_per_char) - 1}"
)

IO.puts("  • Values 0-35: Valid → map to alphanum_lower characters")
IO.puts("  • Values 36-63: Invalid → must reject and retry")

IO.puts("\n## Puid's Optimization: Variable Bit Consumption")
IO.puts(String.duplicate("-", 40))
IO.puts("Bit shift rules: #{inspect(bit_shifts)}")
IO.puts("")

# Interpret the bit shifts
total_values = Puid.Util.pow2(bits_per_char)
IO.puts("Value ranges and bit consumption:")
IO.puts("  • [0-35]: ACCEPT - consume #{bits_per_char} bits, use for character")

# For rejected values
prev_max = charset_size - 1

Enum.reduce(bit_shifts, prev_max, fn {max_val, bits_consumed}, acc ->
  if max_val >= charset_size do
    IO.puts(
      "  • [#{acc + 1}-#{max_val}]: REJECT - consume only #{bits_consumed} bits, then retry"
    )

    max_val
  else
    acc
  end
end)

IO.puts("\n## Probability Analysis")
IO.puts(String.duplicate("-", 40))
p_accept = charset_size / total_values
p_reject = 1 - p_accept

IO.puts(
  "Probability of acceptance: #{charset_size}/#{total_values} = #{Float.round(p_accept * 100, 2)}%"
)

IO.puts(
  "Probability of rejection: #{total_values - charset_size}/#{total_values} = #{Float.round(p_reject * 100, 2)}%"
)

IO.puts("\n## ETE Calculation")
IO.puts(String.duplicate("-", 40))

# Calculate average bits consumed on rejection
reject_count = total_values - charset_size

reject_bits_sum =
  Enum.reduce(charset_size..(total_values - 1), 0, fn value, sum ->
    {_, bits_consumed} = Enum.find(bit_shifts, fn {max_val, _} -> value <= max_val end)
    sum + bits_consumed
  end)

avg_bits_on_reject = reject_bits_sum / reject_count

IO.puts("When we ACCEPT (#{Float.round(p_accept * 100, 2)}% of time):")
IO.puts("  Consume: #{bits_per_char} bits")
IO.puts("")
IO.puts("When we REJECT (#{Float.round(p_reject * 100, 2)}% of time):")
IO.puts("  Average bits consumed: #{Float.round(avg_bits_on_reject, 2)} bits")
IO.puts("  Then must retry (recursively)")

# Expected bits calculation
avg_bits = bits_per_char + p_reject / p_accept * avg_bits_on_reject
ete = theoretical_bits / avg_bits

IO.puts("\nExpected bits per character (accounting for retries):")

IO.puts(
  "  E = #{bits_per_char} + (#{Float.round(p_reject, 4)} / #{Float.round(p_accept, 4)}) × #{Float.round(avg_bits_on_reject, 2)}"
)

IO.puts("  E = #{Float.round(avg_bits, 4)} bits")

IO.puts("\nEntropy Transform Efficiency:")
IO.puts("  ETE = theoretical_bits / avg_bits")
IO.puts("  ETE = #{Float.round(theoretical_bits, 4)} / #{Float.round(avg_bits, 4)}")
IO.puts("  ETE = #{Float.round(ete, 4)}")

# Compare with naive approach
naive_expected = bits_per_char / p_accept
naive_ete = theoretical_bits / naive_expected

IO.puts("\n## Comparison with Naive Approach")
IO.puts(String.duplicate("-", 40))
IO.puts("Naive approach (always consume #{bits_per_char} bits on rejection):")
IO.puts("  Expected bits: #{Float.round(naive_expected, 4)}")
IO.puts("  Naive ETE: #{Float.round(naive_ete, 4)}")
IO.puts("")
IO.puts("Puid's improvement: #{Float.round((ete / naive_ete - 1) * 100, 2)}%")

IO.puts("\n## Why :alphanum_lower is Less Efficient Than :alphanum")
IO.puts(String.duplicate("-", 40))
IO.puts("• Size 36 is further from 64 (power of 2) than :alphanum's 62")

IO.puts(
  "• #{total_values - charset_size} values out of #{total_values} are rejected (#{Float.round(p_reject * 100, 2)}%)"
)

IO.puts(
  "• When rejection occurs, we save #{Float.round(bits_per_char - avg_bits_on_reject, 2)} bits on average"
)

IO.puts(
  "• The lower acceptance rate (#{Float.round(p_accept * 100, 2)}%) means more retries needed"
)

IO.puts("• Result: ETE = #{Float.round(ete, 2)} - still good but not as efficient as :alphanum")

IO.puts("\n## Practical Impact")
IO.puts(String.duplicate("-", 40))
IO.puts("For generating 1 million :alphanum_lower IDs:")

# Assuming 128-bit IDs
id_length = round(128 / theoretical_bits)
total_theoretical_bits = 1_000_000 * id_length * theoretical_bits
total_expected_bits = total_theoretical_bits / ete
total_naive_bits = total_theoretical_bits / naive_ete

IO.puts("  ID length: ~#{id_length} characters (for 128-bit entropy)")
IO.puts("  Theoretical minimum: #{Float.round(total_theoretical_bits / 8 / 1024 / 1024, 2)} MB")
IO.puts("  Puid actual: #{Float.round(total_expected_bits / 8 / 1024 / 1024, 2)} MB")
IO.puts("  Naive approach: #{Float.round(total_naive_bits / 8 / 1024 / 1024, 2)} MB")
IO.puts("  Puid saves: #{Float.round((total_naive_bits - total_expected_bits) / 8 / 1024, 2)} KB")

IO.puts("\n" <> String.duplicate("=", 70))
