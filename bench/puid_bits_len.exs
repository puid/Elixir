# Lists the actual bits and length for each charset configured to the specified target bits
#
# Usage:
#   mix run bench/puid_bits_len.exs
#   mix run bench/puid_bits_len.exs 32 64 96
#   mix run bench/puid_bits_len.exs -md
#   mix run bench/puid_bits_len.exs -md 64 128

charsets = Puid.Chars.predefined()

# Check for markdown flag
args = System.argv()
markdown_mode = "-md" in args
args_without_md = Enum.reject(args, &(&1 == "-md"))

targets =
  case args_without_md do
    [] ->
      [64, 96, 128]

    args ->
      args
      |> Enum.map(fn arg ->
        case Integer.parse(arg) do
          {num, ""} when num > 0 ->
            num

          _ ->
            IO.puts(:stderr, "Warning: ignoring invalid target bits '#{arg}'")
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> case do
        # fallback if all args invalid
        [] -> [64, 128]
        valid_targets -> valid_targets
      end
  end

calc = fn charset, target_bits ->
  ebpc = Puid.Entropy.bits_per_char!(charset)
  len = Puid.Entropy.len_for_bits!(charset, target_bits)
  actual_bits = Float.round(ebpc * len, 2)

  {charset, actual_bits, len}
end

results =
  targets
  |> Enum.map(fn t ->
    {t, charsets |> Enum.map(&calc.(&1, t)) |> Map.new(fn {cs, b, l} -> {cs, {b, l}} end)}
  end)
  |> Map.new()

markdown_output = fn ->
  # Helpers to build header rows with a configurable inter-group filler
  cells = fn prefix_cells, hdrs, filler ->
    prefix_cells ++
      Enum.flat_map(Enum.with_index(targets), fn {target, idx} ->
        group = hdrs.(target)
        if idx < length(targets) - 1, do: group ++ [filler], else: group
      end)
  end

  top_header_cells =
    cells.(["charset"], fn _ -> ["bits", "len"] end, "")

  sep_cells =
    cells.(["---"], fn _ -> ["---:", "---:"] end, "---")

  sub_header_cells =
    cells.([""], fn t -> [Integer.to_string(t), "—"] end, "")

  IO.puts("| " <> Enum.join(top_header_cells, " | ") <> " |")
  IO.puts("| " <> Enum.join(sep_cells, " | ") <> " |")
  IO.puts("| " <> Enum.join(sub_header_cells, " | ") <> " |")

  Enum.each(charsets, fn cs ->
    row_cells =
      [to_string(cs)] ++
        Enum.flat_map(Enum.with_index(targets), fn {t, idx} ->
          {b, l} = Map.fetch!(results[t], cs)
          group = [b, l]
          if idx < length(targets) - 1, do: group ++ [""], else: group
        end)

    IO.puts("| " <> Enum.join(Enum.map(row_cells, &to_string/1), " | ") <> " |")
  end)
end

plain_output = fn ->
  charset_width = charsets |> Enum.map(&(&1 |> to_string() |> String.length())) |> Enum.max()
  charset_width = max(charset_width, 7)

  header_parts = [String.pad_trailing("charset", charset_width)]

  header_parts =
    header_parts ++
      Enum.flat_map(targets, fn t ->
        [
          String.pad_leading("#{t} bits", 10),
          String.pad_leading("len", 5)
        ]
      end)

  IO.puts(Enum.join(header_parts, "  "))
  IO.puts(String.duplicate("-", String.length(Enum.join(header_parts, "  "))))

  Enum.each(charsets, fn cs ->
    row_parts = [String.pad_trailing(to_string(cs), charset_width)]

    row_parts =
      row_parts ++
        Enum.flat_map(targets, fn t ->
          {b, l} = Map.fetch!(results[t], cs)

          [
            String.pad_leading(to_string(b), 10),
            String.pad_leading(to_string(l), 5)
          ]
        end)

    IO.puts(Enum.join(row_parts, "  "))
  end)
end

if markdown_mode do
  markdown_output.()
else
  plain_output.()
end
