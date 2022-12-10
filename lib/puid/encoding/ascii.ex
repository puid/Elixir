# MIT License
#
# Copyright (c) 2019-2022 Knoxen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

defmodule Puid.Encoding.ASCII do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      charlist = unquote(opts)[:charlist]
      bits_per_char = unquote(opts)[:bits_per_char]
      puid_len = unquote(opts)[:puid_len]

      puid_size = puid_len * bits_per_char
      single_chunk_size = 8 * bits_per_char
      pair_chunk_size = 2 * single_chunk_size
      pair_chunks_size = div(puid_size, pair_chunk_size) * pair_chunk_size

      @puid_bits_per_char bits_per_char
      @puid_bits_per_pair 2 * bits_per_char
      @puid_charlist charlist
      @puid_char_count length(charlist)
      @puid_pair_chunks_size pair_chunks_size
      @puid_single_chunk_size single_chunk_size

      cond do
        puid_size < @puid_single_chunk_size ->
          def encode(bits), do: encode_unchunked(bits)

        puid_size == @puid_single_chunk_size ->
          def encode(bits), do: encode_single(bits)

        puid_size == @puid_pair_chunks_size ->
          def encode(bits), do: encode_pairs(bits)

        puid_size < @puid_pair_chunks_size ->
          def encode(bits) do
            <<
              single_chunk::size(@puid_single_chunk_size)-bits,
              sub_chunk::bits
            >> = bits

            single = encode_single(single_chunk)
            subchunk = encode_unchunked(sub_chunk)

            <<single::binary, subchunk::binary>>
          end

        puid_size < @puid_pair_chunks_size + @puid_single_chunk_size ->
          def encode(bits) do
            <<
              pair_chunks::size(@puid_pair_chunks_size)-bits,
              sub_chunk::bits
            >> = bits

            pairs = encode_pairs(pair_chunks)
            subchunk = encode_unchunked(sub_chunk)

            <<pairs::binary, subchunk::binary>>
          end

        true ->
          def encode(bits) do
            <<
              pair_chunks::size(@puid_pair_chunks_size)-bits,
              single_chunk::size(@puid_single_chunk_size)-bits,
              sub_chunk::bits
            >> = bits

            pairs = encode_pairs(pair_chunks)
            single = encode_single(single_chunk)
            subchunk = encode_unchunked(sub_chunk)

            <<pairs::binary, single::binary, subchunk::binary>>
          end
      end

      defmacrop pair_encoding(value) do
        quote do
          case unquote(value) do
            unquote(pair_encoding_clauses())
          end
        end
      end

      defp pair_encoding_clauses() do
        char_vals = @puid_charlist |> Enum.with_index()

        for {char1, val1} <- char_vals,
            {char2, val2} <- char_vals do
          pair = bsl(char1, 8) + char2
          value = bsl(val1, @puid_bits_per_char) + val2

          [pair_clause] = quote(do: (unquote(value) -> unquote(pair)))
          pair_clause
        end
      end

      defmacrop single_encoding(value) do
        quote do
          case unquote(value) do
            unquote(single_encoding_clauses())
          end
        end
      end

      defp single_encoding_clauses() do
        for {char, value} <-
              @puid_charlist
              |> Enum.with_index() do
          [single_clause] = quote(do: (unquote(value) -> unquote(char)))
          single_clause
        end
      end

      defp pair_encode(char), do: pair_encoding(char)

      defp single_encode(char), do: single_encoding(char)

      defp encode_pairs(chunks) do
        case chunks do
          <<>> ->
            <<>>

          _ ->
            for <<p1::@puid_bits_per_pair, p2::@puid_bits_per_pair, p3::@puid_bits_per_pair,
                  p4::@puid_bits_per_pair, p5::@puid_bits_per_pair, p6::@puid_bits_per_pair,
                  p7::@puid_bits_per_pair, p8::@puid_bits_per_pair <- chunks>>,
                into: <<>> do
              <<
                pair_encode(p1)::16,
                pair_encode(p2)::16,
                pair_encode(p3)::16,
                pair_encode(p4)::16,
                pair_encode(p5)::16,
                pair_encode(p6)::16,
                pair_encode(p7)::16,
                pair_encode(p8)::16
              >>
            end
        end
      end

      defp encode_single(chunk) do
        case chunk do
          <<>> ->
            <<>>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
            s4::@puid_bits_per_char, s5::@puid_bits_per_char, s6::@puid_bits_per_char,
            s7::@puid_bits_per_char, s8::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::8,
              single_encode(s2)::8,
              single_encode(s3)::8,
              single_encode(s4)::8,
              single_encode(s5)::8,
              single_encode(s6)::8,
              single_encode(s7)::8,
              single_encode(s8)::8
            >>
        end
      end

      defp encode_unchunked(chunk) do
        case chunk do
          <<>> ->
            <<>>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
            s4::@puid_bits_per_char, s5::@puid_bits_per_char, s6::@puid_bits_per_char,
            s7::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::8,
              single_encode(s2)::8,
              single_encode(s3)::8,
              single_encode(s4)::8,
              single_encode(s5)::8,
              single_encode(s6)::8,
              single_encode(s7)::8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
            s4::@puid_bits_per_char, s5::@puid_bits_per_char, s6::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::8,
              single_encode(s2)::8,
              single_encode(s3)::8,
              single_encode(s4)::8,
              single_encode(s5)::8,
              single_encode(s6)::8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
            s4::@puid_bits_per_char, s5::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::8,
              single_encode(s2)::8,
              single_encode(s3)::8,
              single_encode(s4)::8,
              single_encode(s5)::8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
            s4::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::8,
              single_encode(s2)::8,
              single_encode(s3)::8,
              single_encode(s4)::8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::8,
              single_encode(s2)::8,
              single_encode(s3)::8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::8,
              single_encode(s2)::8
            >>

          <<s1::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::8
            >>
        end
      end
    end
  end
end
