# Lists all predefined Puid charsets
#
# Usage:
#   mix run bench/charsets.exs       # Plain text output (default)
#   mix run bench/charsets.exs -md   # Markdown table output

markdown_mode = System.argv() |> Enum.member?("-md")

md_codepoint = fn
  ?| -> [?\\, ?|]
  ?* -> [?\\, ?*]
  ?_ -> [?\\, ?_]
  ?[ -> [?\\, ?[]
  ?] -> [?\\, ?]]
  ?` -> [?\\, ?`]
  codepoint -> codepoint
end

get_puid_ete = fn charset ->
  metric = Puid.Chars.metrics(charset)
  metric.ete
end

md_output = fn ->
  IO.puts("# Puid Predefined Charsets")
  IO.puts("")
  IO.puts("| Name | Count | ERE | ETE | Characters |")
  IO.puts("|------|--------|-----|-----|------------|")

  Puid.Chars.predefined()
  |> Enum.each(fn charset ->
    chars = Puid.Chars.charlist!(charset)
    char_count = length(chars)
    bpc = :math.log2(char_count)

    ete = get_puid_ete.(charset)

    chars_string = chars |> Enum.map(md_codepoint) |> List.to_string()

    IO.puts(
      "| :#{charset} | #{char_count} | #{Float.round(bpc, 2)} | #{Float.round(ete, 2)} | #{chars_string} |"
    )
  end)
end

plain_output = fn ->
  Puid.Chars.predefined()
  |> Enum.each(fn charset ->
    chars = Puid.Chars.charlist!(charset)
    chars_string = List.to_string(chars)
    IO.puts("#{charset}: #{chars_string}")
  end)
end

output = fn
  true -> md_output.()
  false -> plain_output.()
end

output.(markdown_mode)
