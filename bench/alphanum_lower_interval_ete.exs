# Detailed ETE Analysis for :alphanum_lower charset using :interval sampler
# Shows how interval/range sampling recycles leftover entropy for 36 characters

charset = :alphanum_lower
chars = Puid.Chars.charlist!(charset)
charset_size = length(chars)
theoretical_bits = :math.log2(charset_size)
bits_per_char = Puid.Util.log_ceil(charset_size)
total_values = Puid.Util.pow2(bits_per_char)

interval_metrics = Puid.Chars.metrics(charset, :interval)
bit_shift_metrics = Puid.Chars.metrics(charset, :bit_shift)

p_accept_slice = charset_size / total_values
naive_expected = bits_per_char / p_accept_slice
naive_ete = theoretical_bits / naive_expected

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("DETAILED ETE ANALYSIS (:interval): :alphanum_lower")
IO.puts(String.duplicate("=", 70))

IO.puts("\n## Charset Properties")
IO.puts(String.duplicate("-", 40))
IO.puts("Charset: :#{charset}")
IO.puts("Characters: #{chars}")
IO.puts("Charset size: #{charset_size} characters")
IO.puts("Theoretical bits per char: #{Float.round(theoretical_bits, 4)} bits")
IO.puts("ceil(log2(charset_size)): #{bits_per_char} bits")
IO.puts("6-bit slice range: 0-#{total_values - 1}")

IO.puts("\n## Interval Sampler State Model")
IO.puts(String.duplicate("-", 40))
IO.puts("State is {x, m} where x is uniformly distributed in [0, m)")
IO.puts("Start state: {0, 1}")
IO.puts("")
IO.puts("1) While m < #{charset_size}, pull one byte b and expand:")
IO.puts("     {x, m} -> {x * 256 + b, m * 256}")
IO.puts("2) Once m >= #{charset_size}, compute:")
IO.puts("     q = div(m, #{charset_size})")
IO.puts("     t = q * #{charset_size}")
IO.puts("3) If x < t:")
IO.puts("     accept value = rem(x, #{charset_size})")
IO.puts("     next state = {div(x, #{charset_size}), q}")
IO.puts("4) Else (x >= t):")
IO.puts("     reject narrow overflow band only")
IO.puts("     next state = {x - t, m - t}")
IO.puts("     retry from that carried state")

IO.puts("\n## First Decision (after one byte)")
IO.puts(String.duplicate("-", 40))
m0 = 256
q0 = div(m0, charset_size)
t0 = q0 * charset_size
overflow0 = m0 - t0
overflow_pct0 = overflow0 / m0 * 100

IO.puts("With one byte: m = #{m0}")
IO.puts("q = div(256, 36) = #{q0}")
IO.puts("t = q * 36 = #{t0}")
IO.puts("Accept region: x < #{t0} (#{Float.round(t0 / m0 * 100, 2)}%)")
IO.puts("Overflow region: x >= #{t0} (#{overflow0}/256 = #{Float.round(overflow_pct0, 2)}%)")

IO.puts("\n## Example Paths")
IO.puts(String.duplicate("-", 40))
IO.puts("Accept path with one byte:")
x_accept = 250
value_accept = rem(x_accept, charset_size)
next_x_accept = div(x_accept, charset_size)
next_m_accept = q0

IO.puts("  x=#{x_accept} < #{t0}")
IO.puts("  value = rem(#{x_accept}, 36) = #{value_accept}")
IO.puts("  next state = {#{next_x_accept}, #{next_m_accept}}")

IO.puts("\nReject-then-recover path:")
x_reject = 254
next_x_reject = x_reject - t0
next_m_reject = m0 - t0

IO.puts("  x=#{x_reject} >= #{t0} -> reject overflow band")
IO.puts("  carry state = {#{next_x_reject}, #{next_m_reject}}")

IO.puts(
  "  pull next byte b=173 -> {#{next_x_reject}*256+173, #{next_m_reject}*256} = {685, 1024}"
)

q1 = div(1024, charset_size)
t1 = q1 * charset_size
value_recovered = rem(685, charset_size)
next_x_recovered = div(685, charset_size)

IO.puts("  q = div(1024, 36) = #{q1}, t = #{t1}")
IO.puts("  685 < #{t1} -> accept value #{value_recovered}")
IO.puts("  next state = {#{next_x_recovered}, #{q1}}")

IO.puts("\n## ETE Comparison")
IO.puts(String.duplicate("-", 40))
interval_avg_bits = interval_metrics.avg_bits
interval_ete = interval_metrics.ete
bit_shift_avg_bits = bit_shift_metrics.avg_bits
bit_shift_ete = bit_shift_metrics.ete

IO.puts("Naive full-slice rejection:")
IO.puts("  avg bits/char: #{Float.round(naive_expected, 4)}")
IO.puts("  ETE: #{Float.round(naive_ete, 4)}")
IO.puts("")
IO.puts(":bit_shift sampler:")
IO.puts("  avg bits/char: #{Float.round(bit_shift_avg_bits, 4)}")
IO.puts("  ETE: #{Float.round(bit_shift_ete, 4)}")
IO.puts("")
IO.puts(":interval sampler:")
IO.puts("  avg bits/char: #{Float.round(interval_avg_bits, 4)}")
IO.puts("  ETE: #{Float.round(interval_ete, 4)}")

improve_vs_naive = (interval_ete / naive_ete - 1) * 100
improve_vs_bit_shift = (interval_ete / bit_shift_ete - 1) * 100

IO.puts("")
IO.puts("Interval improvement vs naive: #{Float.round(improve_vs_naive, 2)}%")
IO.puts("Interval improvement vs bit_shift: #{Float.round(improve_vs_bit_shift, 2)}%")

IO.puts("\n## Practical Impact")
IO.puts(String.duplicate("-", 40))
IO.puts("For generating 1 million :alphanum_lower IDs:")

id_length = round(128 / theoretical_bits)
total_theoretical_bits = 1_000_000 * id_length * theoretical_bits
total_naive_bits = total_theoretical_bits / naive_ete
total_bit_shift_bits = total_theoretical_bits / bit_shift_ete
total_interval_bits = total_theoretical_bits / interval_ete

IO.puts("  ID length: ~#{id_length} characters (for 128-bit entropy)")
IO.puts("  Theoretical minimum: #{Float.round(total_theoretical_bits / 8 / 1024 / 1024, 2)} MB")
IO.puts("  Naive approach: #{Float.round(total_naive_bits / 8 / 1024 / 1024, 2)} MB")
IO.puts("  bit_shift actual: #{Float.round(total_bit_shift_bits / 8 / 1024 / 1024, 2)} MB")
IO.puts("  interval actual: #{Float.round(total_interval_bits / 8 / 1024 / 1024, 2)} MB")

IO.puts(
  "  interval saves vs bit_shift: #{Float.round((total_bit_shift_bits - total_interval_bits) / 8 / 1024, 2)} KB"
)

IO.puts("\n" <> String.duplicate("=", 70))
