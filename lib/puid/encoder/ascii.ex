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

defmodule Puid.Encoder.ASCII do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      charlist = unquote(opts)[:charlist]
      bits_per_char = unquote(opts)[:bits_per_char]
      puid_len = unquote(opts)[:puid_len]

      puid_size = puid_len * bits_per_char
      single_chunk_size = 8 * bits_per_char
      pair_chunk_size = 2 * single_chunk_size
      pair_chunks_size = max(div(puid_size, pair_chunk_size) * pair_chunk_size, pair_chunk_size)

      @puid_bits_per_char bits_per_char
      @puid_bits_per_pair 2 * bits_per_char
      @puid_charlist charlist
      @puid_char_count length(charlist)

      @puid_single_chunk_size single_chunk_size
      @puid_pair_chunk_size pair_chunk_size
      @puid_pair_chunks_size pair_chunks_size

      cond do
        # Less than a single chunk
        puid_size < @puid_single_chunk_size ->
          def encode(bits), do: encode_singles(bits)

        # Equal to a single chunk
        puid_size == @puid_single_chunk_size ->
          def encode(bits), do: encode_singles(bits)

        # Less than a pair chunk
        puid_size < @puid_pair_chunk_size ->
          def encode(bits) do
            <<
              single_chunk::size(@puid_single_chunk_size)-bits,
              sub_chunk::bits
            >> = bits

            single = encode_singles(single_chunk)
            subchunk = encode_singles(sub_chunk)

            <<single::binary, subchunk::binary>>
          end

        # Equal to one or more pair chunks
        puid_size == @puid_pair_chunks_size ->
          def encode(bits), do: encode_pairs(bits)

        # Less than one or more pair chunks plus a single chunk
        puid_size < @puid_pair_chunks_size + @puid_single_chunk_size ->
          def encode(bits) do
            <<
              pair_chunks::size(@puid_pair_chunks_size)-bits,
              sub_chunk::bits
            >> = bits

            pairs = encode_pairs(pair_chunks)
            subchunk = encode_singles(sub_chunk)

            <<pairs::binary, subchunk::binary>>
          end

        # Equal to one or more pair chunks plus a single chunk
        puid_size == @puid_pair_chunks_size + @puid_single_chunk_size ->
          def encode(bits) do
            <<
              pair_chunks::size(@puid_pair_chunks_size)-bits,
              single_chunk::size(@puid_single_chunk_size)-bits
            >> = bits

            pairs = encode_pairs(pair_chunks)
            single = encode_singles(single_chunk)

            <<pairs::binary, single::binary>>
          end

        # Greater than one or more pair chunks plus a single chunk
        true ->
          def encode(bits) do
            <<
              pair_chunks::size(@puid_pair_chunks_size)-bits,
              single_chunk::size(@puid_single_chunk_size)-bits,
              sub_chunk::bits
            >> = bits

            pairs = encode_pairs(pair_chunks)
            single = encode_singles(single_chunk)
            subchunk = encode_singles(sub_chunk)

            <<pairs::binary, single::binary, subchunk::binary>>
          end
      end

      defmacrop pair_encoding(v) do
        quote do
          case unquote(v) do
            unquote(pair_encoding_clauses())
          end
        end
      end

      defp pair_encoding_clauses() do
        cv = @puid_charlist |> Enum.with_index()

        for {c1, v1} <- cv,
            {c2, v2} <- cv do
          cc = bsl(c1, 8) + c2
          v = bsl(v1, @puid_bits_per_char) + v2

          [pair_clause] = quote(do: (unquote(v) -> unquote(cc)))
          pair_clause
        end
      end

      defmacrop single_encoding(v) do
        quote do
          case unquote(v) do
            unquote(single_encoding_clauses())
          end
        end
      end

      defp single_encoding_clauses() do
        for {c, v} <-
              @puid_charlist
              |> Enum.with_index() do
          [single_clause] = quote(do: (unquote(v) -> unquote(c)))
          single_clause
        end
      end

      defp pair_encode(vv), do: pair_encoding(vv)

      defp single_encode(v), do: single_encoding(v)

      defp encode_pairs(<<>>), do: <<>>

      defp encode_pairs(vv_chunks) do
        for <<vv1::@puid_bits_per_pair, vv2::@puid_bits_per_pair, vv3::@puid_bits_per_pair,
              vv4::@puid_bits_per_pair, vv5::@puid_bits_per_pair, vv6::@puid_bits_per_pair,
              vv7::@puid_bits_per_pair, vv8::@puid_bits_per_pair <- vv_chunks>>,
            into: <<>>,
            do: <<
              pair_encode(vv1)::16,
              pair_encode(vv2)::16,
              pair_encode(vv3)::16,
              pair_encode(vv4)::16,
              pair_encode(vv5)::16,
              pair_encode(vv6)::16,
              pair_encode(vv7)::16,
              pair_encode(vv8)::16
            >>
      end

      defp encode_singles(
             <<v1::@puid_bits_per_char, v2::@puid_bits_per_char, v3::@puid_bits_per_char,
               v4::@puid_bits_per_char, v5::@puid_bits_per_char, v6::@puid_bits_per_char,
               v7::@puid_bits_per_char, v8::@puid_bits_per_char>>
           ),
           do: <<
             single_encode(v1)::8,
             single_encode(v2)::8,
             single_encode(v3)::8,
             single_encode(v4)::8,
             single_encode(v5)::8,
             single_encode(v6)::8,
             single_encode(v7)::8,
             single_encode(v8)::8
           >>

      defp encode_singles(
             <<v1::@puid_bits_per_char, v2::@puid_bits_per_char, v3::@puid_bits_per_char,
               v4::@puid_bits_per_char, v5::@puid_bits_per_char, v6::@puid_bits_per_char,
               v7::@puid_bits_per_char>>
           ),
           do: <<
             single_encode(v1)::8,
             single_encode(v2)::8,
             single_encode(v3)::8,
             single_encode(v4)::8,
             single_encode(v5)::8,
             single_encode(v6)::8,
             single_encode(v7)::8
           >>

      defp encode_singles(
             <<v1::@puid_bits_per_char, v2::@puid_bits_per_char, v3::@puid_bits_per_char,
               v4::@puid_bits_per_char, v5::@puid_bits_per_char, v6::@puid_bits_per_char>>
           ),
           do: <<
             single_encode(v1)::8,
             single_encode(v2)::8,
             single_encode(v3)::8,
             single_encode(v4)::8,
             single_encode(v5)::8,
             single_encode(v6)::8
           >>

      defp encode_singles(
             <<v1::@puid_bits_per_char, v2::@puid_bits_per_char, v3::@puid_bits_per_char,
               v4::@puid_bits_per_char, v5::@puid_bits_per_char>>
           ),
           do: <<
             single_encode(v1)::8,
             single_encode(v2)::8,
             single_encode(v3)::8,
             single_encode(v4)::8,
             single_encode(v5)::8
           >>

      defp encode_singles(
             <<v1::@puid_bits_per_char, v2::@puid_bits_per_char, v3::@puid_bits_per_char,
               v4::@puid_bits_per_char>>
           ),
           do: <<
             single_encode(v1)::8,
             single_encode(v2)::8,
             single_encode(v3)::8,
             single_encode(v4)::8
           >>

      defp encode_singles(
             <<v1::@puid_bits_per_char, v2::@puid_bits_per_char, v3::@puid_bits_per_char>>
           ),
           do: <<
             single_encode(v1)::8,
             single_encode(v2)::8,
             single_encode(v3)::8
           >>

      defp encode_singles(<<v1::@puid_bits_per_char, v2::@puid_bits_per_char>>),
        do: <<
          single_encode(v1)::8,
          single_encode(v2)::8
        >>

      defp encode_singles(<<v1::@puid_bits_per_char>>),
        do: <<
          single_encode(v1)::8
        >>

      defp encode_singles(<<>>),
        do: <<>>
    end
  end
end
