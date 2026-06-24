# Compute ETE (Entropy Transform Efficiency) for each of Puid's predefined charsets
# by analyzing the actual bit slicing algorithm
#
# Usage:
#   MIX_ENV=test mix run bench/puid_interval_ete.exs

Code.require_file("benchmark_helper.exs", __DIR__)
import Bitwise

defmodule Bench.PuidIntervalETE do
  @moduledoc """
  Computes Entropy Transform Efficiency (ETE) for all Puid charsets.
  Based on Puid's interval sampler behavior:
  - For power-of-2 charsets: ETE = 1.0 (no rejection)
  - For non-power-of-2: Uses stateful interval recycling
  """

  # Predefined charsets in Puid
  @charsets [
    # 52 chars: A-Z, a-z
    :alpha,
    # 26 chars: a-z
    :alpha_lower,
    # 26 chars: A-Z
    :alpha_upper,
    # 62 chars: A-Za-z0-9
    :alphanum,
    # 36 chars: a-z0-9
    :alphanum_lower,
    # 36 chars: A-Z0-9
    :alphanum_upper,
    # 32 chars: A-Z2-7 (RFC 4648)
    :base32,
    # 32 chars: 0-9a-v (RFC 4648 extended hex)
    :base32_hex,
    # 32 chars: 0-9A-V
    :base32_hex_upper,
    # 32 chars: 0-9ABCDEFGHJKMNPQRSTVWXYZ (Crockford's base32)
    :crockford32,
    # 10 chars: 0-9
    :decimal,
    # 16 chars: 0-9a-f
    :hex,
    # 16 chars: 0-9A-F
    :hex_upper,
    # 32 chars: human-friendly (no ambiguous chars)
    :safe32,
    # 64 chars: URL-safe base64 alphabet
    :safe64,
    # 90 chars: ASCII printable minus quotes/backslash
    :safe_ascii,
    # 28 chars: ASCII symbols (32 - 4 quotes/backslash)
    :symbol,
    # 32 chars: word-boundary safe
    :wordSafe32
  ]

  def run do
    IO.puts("\n# Puid Entropy Transform Efficiency (ETE) Analysis - :interval")
    IO.puts("")
    IO.puts("## Overview")
    IO.puts("ETE calculation based on Puid's :interval sampler.")
    IO.puts("Includes direct comparison against :bit_shift for each charset.")
    IO.puts("")

    charset_data = Enum.map(@charsets, &analyze_charset/1)

    IO.puts("## Power-of-2 Charsets (ETE = 1.0)")
    IO.puts("These charsets have perfect efficiency - no bits are ever rejected.")
    IO.puts("")

    power_of_2_data = Enum.filter(charset_data, fn data -> data.is_power_of_2 end)
    print_charset_table(power_of_2_data)

    IO.puts("\n## Non-Power-of-2 Charsets (ETE Calculation)")
    IO.puts("These charsets use interval recycling and are compared against :bit_shift.")
    IO.puts("")

    non_power_of_2_data =
      Enum.filter(charset_data, fn data -> not data.is_power_of_2 end)
      # Sort by ETE, best first
      |> Enum.sort_by(& &1.ete, :desc)

    print_charset_table_detailed(non_power_of_2_data)

    print_summary(charset_data)
  end

  defp pow2(n), do: 1 <<< n

  defp analyze_charset(charset_atom) do
    module_name =
      Module.concat([PuidIntervalETE, charset_atom |> to_string() |> Macro.camelize()])

    defmodule module_name do
      use Puid, bits: 128, chars: charset_atom, sampler: :interval
    end

    info = apply(module_name, :info, [])
    charset_size = String.length(info.characters)
    theoretical_bits_per_char = :math.log2(charset_size)
    id_length = info.length

    is_power_of_2 = Puid.Util.pow2?(charset_size)

    interval_metric = Puid.Chars.metrics(charset_atom, :interval)
    bit_shift_metric = Puid.Chars.metrics(charset_atom, :bit_shift)

    {ete, avg_bits, bit_shifts} =
      {interval_metric.ete, interval_metric.avg_bits, interval_metric.bit_shifts}

    bit_shift_ete = bit_shift_metric.ete

    gain_percent =
      if bit_shift_ete == 0.0 do
        0.0
      else
        (ete / bit_shift_ete - 1) * 100
      end

    actual_bits = id_length * avg_bits
    random_bytes = actual_bits / 8
    theoretical_bits = id_length * theoretical_bits_per_char
    bits_per_char = Puid.Util.log_ceil(charset_size)
    slice_values = pow2(bits_per_char)

    %{
      name: charset_atom,
      size: charset_size,
      bits_per_char: Float.round(theoretical_bits_per_char, 2),
      slicing_bits: bits_per_char,
      slice_values: slice_values,
      is_power_of_2: is_power_of_2,
      ete: Float.round(ete, 4),
      bit_shift_ete: Float.round(bit_shift_ete, 4),
      gain_percent: Float.round(gain_percent, 2),
      expected_bits_per_char: Float.round(avg_bits, 2),
      id_length: id_length,
      theoretical_bytes: Float.round(theoretical_bits / 8, 2),
      actual_bytes: Float.round(random_bytes, 2),
      waste_percent: Float.round((1 - ete) * 100, 2),
      bit_shifts: bit_shifts
    }
  end

  defp print_charset_table(data) do
    IO.puts(
      "| Charset           | Size | Bits/Char | Interval ETE | BitShift ETE | Gain % | ID Length | Theory Bytes | Actual Bytes | Waste % |"
    )

    IO.puts(
      "|-------------------|------|-----------|--------------|--------------|--------|-----------|--------------|--------------|---------|"
    )

    Enum.each(data, fn d ->
      IO.puts(
        "| #{pad(to_string(d.name), 17)} | #{pad_number(d.size, 4)} | #{pad_float(d.bits_per_char, 9, 2)} | #{pad_float(d.ete, 12, 2)} | #{pad_float(d.bit_shift_ete, 12, 2)} | #{pad_float(d.gain_percent, 6, 2)} | #{pad_number(d.id_length, 9)} | #{pad_float(d.theoretical_bytes, 12, 2)} | #{pad_float(d.actual_bytes, 12, 2)} | #{pad_float(d.waste_percent, 7, 2)} |"
      )
    end)
  end

  defp print_charset_table_detailed(data) do
    IO.puts(
      "| Charset           | Size | Theory Bits | Slice Bits | Expected Bits | Interval ETE | BitShift ETE | Gain % | ID Len | Theory Bytes | Actual Bytes | Waste % |"
    )

    IO.puts(
      "|-------------------|------|-------------|------------|---------------|--------------|--------------|--------|--------|--------------|--------------|---------|"
    )

    Enum.each(data, fn d ->
      IO.puts(
        "| #{pad(to_string(d.name), 17)} | #{pad_number(d.size, 4)} | #{pad_float(d.bits_per_char, 11, 2)} | #{pad_number(d.slicing_bits, 10)} | #{pad_float(d.expected_bits_per_char, 13, 2)} | #{pad_float(d.ete, 12, 2)} | #{pad_float(d.bit_shift_ete, 12, 2)} | #{pad_float(d.gain_percent, 6, 2)} | #{pad_number(d.id_length, 6)} | #{pad_float(d.theoretical_bytes, 12, 2)} | #{pad_float(d.actual_bytes, 12, 2)} | #{pad_float(d.waste_percent, 7, 2)} |"
      )
    end)

    IO.puts("\n### Interval vs BitShift Gains")
    IO.puts("")

    Enum.each(data, fn d ->
      if not d.is_power_of_2 do
        IO.puts("**#{d.name}**:")
        IO.puts("  Interval ETE: #{Float.round(d.ete, 4)}")
        IO.puts("  BitShift ETE: #{Float.round(d.bit_shift_ete, 4)}")
        IO.puts("  Interval gain: #{Float.round(d.gain_percent, 2)}%")

        IO.puts("")
      end
    end)
  end

  defp print_summary(all_data) do
    perfect_count = Enum.count(all_data, & &1.is_power_of_2)
    imperfect_count = length(all_data) - perfect_count

    imperfect_data = Enum.filter(all_data, fn d -> not d.is_power_of_2 end)

    if length(imperfect_data) > 0 do
      avg_ete = Enum.sum(Enum.map(imperfect_data, & &1.ete)) / length(imperfect_data)
      avg_waste = Enum.sum(Enum.map(imperfect_data, & &1.waste_percent)) / length(imperfect_data)
      best_ete = Enum.max_by(imperfect_data, & &1.ete)
      worst_ete = Enum.min_by(imperfect_data, & &1.ete)

      IO.puts("\n## Summary Statistics")
      IO.puts("")
      IO.puts("### Charset Distribution")
      IO.puts("- Total charsets: #{length(all_data)}")
      IO.puts("- Power-of-2 charsets: #{perfect_count} (ETE = 1.0)")
      IO.puts("- Non-power-of-2 charsets: #{imperfect_count}")
      IO.puts("")

      IO.puts("### Non-Power-of-2 Efficiency")
      avg_gain = Enum.sum(Enum.map(imperfect_data, & &1.gain_percent)) / length(imperfect_data)

      IO.puts("- Average interval ETE: #{Float.round(avg_ete, 2)}")
      IO.puts("- Average interval gain vs bit_shift: #{Float.round(avg_gain, 2)}%")
      IO.puts("- Average waste: #{Float.round(avg_waste, 2)}%")

      IO.puts(
        "- Best ETE: #{Float.round(best_ete.ete, 2)} (#{best_ete.name}, #{best_ete.size} chars)"
      )

      IO.puts(
        "- Worst ETE: #{Float.round(worst_ete.ete, 2)} (#{worst_ete.name}, #{worst_ete.size} chars)"
      )

      IO.puts("")

      IO.puts("### Key Insights")
      IO.puts("- The :interval strategy can significantly improve ETE on non-power-of-2 charsets")
      IO.puts("- Power-of-2 charsets remain at perfect efficiency for both samplers")
      IO.puts("- Gains are largest when charset size is far from nearby powers of 2")
      IO.puts("- :interval trades extra compute for lower entropy waste")
    end
  end

  defp pad(string, width) do
    String.pad_trailing(string, width)
  end

  defp pad_number(number, width) do
    number
    |> to_string()
    |> String.pad_leading(width)
  end

  defp pad_float(float, width, decimals) do
    float
    |> :erlang.float_to_binary(decimals: decimals)
    |> String.pad_leading(width)
  end
end

Bench.PuidIntervalETE.run()
