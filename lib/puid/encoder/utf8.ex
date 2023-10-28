# MIT License
#
# Copyright (c) 2019-2023 Knoxen
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

defmodule Puid.Encoder.Utf8 do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      charlist = unquote(opts)[:charlist]
      bits_per_char = unquote(opts)[:bits_per_char]
      puid_len = unquote(opts)[:puid_len]

      puid_size = puid_len * bits_per_char
      single_chunk_size = 8 * bits_per_char
      single_chunks_size = div(puid_size, single_chunk_size) * single_chunk_size

      @puid_bits_per_char bits_per_char
      @puid_charlist charlist
      @puid_char_count length(charlist)
      @puid_single_chunks_size single_chunks_size

      @spec encode(bits :: bitstring()) :: String.t()
      def encode(bits)

      cond do
        # Less than a single chunk
        puid_size < @puid_single_chunks_size ->
          def encode(bits), do: encode_unchunked(bits)

        # Equal to one or more a single chunks
        puid_size == @puid_single_chunks_size ->
          def encode(bits), do: encode_singles(bits)

        # Not a multiple of a single chunks
        true ->
          def encode(bits) do
            <<
              single_chunks::size(@puid_single_chunks_size)-bits,
              sub_chunk::bits
            >> = bits

            singles = encode_singles(single_chunks)
            subchunk = encode_unchunked(sub_chunk)

            <<singles::binary, subchunk::binary>>
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

      def single_encode(char), do: single_encoding(char)

      defp encode_singles(chunks) do
        case chunks do
          <<>> ->
            <<>>

          _ ->
            for <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
                  s4::@puid_bits_per_char, s5::@puid_bits_per_char, s6::@puid_bits_per_char,
                  s7::@puid_bits_per_char, s8::@puid_bits_per_char <- chunks>>,
                into: <<>> do
              <<
                single_encode(s1)::utf8,
                single_encode(s2)::utf8,
                single_encode(s3)::utf8,
                single_encode(s4)::utf8,
                single_encode(s5)::utf8,
                single_encode(s6)::utf8,
                single_encode(s7)::utf8,
                single_encode(s8)::utf8
              >>
            end
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
              single_encode(s1)::utf8,
              single_encode(s2)::utf8,
              single_encode(s3)::utf8,
              single_encode(s4)::utf8,
              single_encode(s5)::utf8,
              single_encode(s6)::utf8,
              single_encode(s7)::utf8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
            s4::@puid_bits_per_char, s5::@puid_bits_per_char, s6::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::utf8,
              single_encode(s2)::utf8,
              single_encode(s3)::utf8,
              single_encode(s4)::utf8,
              single_encode(s5)::utf8,
              single_encode(s6)::utf8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
            s4::@puid_bits_per_char, s5::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::utf8,
              single_encode(s2)::utf8,
              single_encode(s3)::utf8,
              single_encode(s4)::utf8,
              single_encode(s5)::utf8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char,
            s4::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::utf8,
              single_encode(s2)::utf8,
              single_encode(s3)::utf8,
              single_encode(s4)::utf8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char, s3::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::utf8,
              single_encode(s2)::utf8,
              single_encode(s3)::utf8
            >>

          <<s1::@puid_bits_per_char, s2::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::utf8,
              single_encode(s2)::utf8
            >>

          <<s1::@puid_bits_per_char>> ->
            <<
              single_encode(s1)::utf8
            >>
        end
      end
    end
  end
end
