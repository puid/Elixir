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

defmodule Puid.Decoder.ASCII do
  import Puid.Util

  defmacro __using__(opts) do
    quote do
      charlist = unquote(opts)[:charlist]
      puid_len = unquote(opts)[:puid_len]

      char_count = length(charlist)

      bits_per_char = log_ceil(char_count)
      bits_per_puid = puid_len * bits_per_char

      @puid_len puid_len
      @puid_charlist charlist
      @puid_bits_per_char bits_per_char
      @puid_bits_per_pair 2 * bits_per_char

      @spec decode(puid :: String.t()) :: bitstring() | {:error, String.t()}
      def decode(puid)

      def decode(<<_::binary-size(@puid_len)>> = puid) do
        try do
          puid |> decode_puid_into(<<>>)
        rescue
          _ ->
            {:error, "unable to decode"}
        end
      end

      def decode(_),
        do: {:error, "unable to decode"}

      @spec decode_puid_into(bytes :: binary(), bits :: bitstring()) :: bitstring()
      defp decode_puid_into(bytes, bits)

      defp decode_puid_into(<<>>, bits),
        do: bits

      defp decode_puid_into(<<c::8>>, bits) do
        c_bits = decode_single(c)
        <<bits::bits, c_bits::bits>>
      end

      defp decode_puid_into(<<cc::16, rest::binary>>, bits) do
        cc_bits = decode_pair(cc)
        decode_puid_into(rest, <<bits::bits, cc_bits::bits>>)
      end

      defp chars_values(), do: @puid_charlist |> Enum.with_index()

      defmacrop pair_decoder(cc) do
        quote do
          case unquote(cc) do
            unquote(pair_decoder_clauses())
          end
        end
      end

      defp pair_decoder_clauses() do
        cv = chars_values()

        for {c1, v1} <- cv, {c2, v2} <- cv do
          cc = Bitwise.bsl(c1, 8) + c2
          v = Bitwise.bsl(v1, @puid_bits_per_char) + v2

          [clause] = quote(do: (unquote(cc) -> unquote(v)))
          clause
        end
      end

      defmacrop single_decoder(c) do
        quote do
          case unquote(c) do
            unquote(single_decoder_clauses())
          end
        end
      end

      defp single_decoder_clauses() do
        for {c, v} <- chars_values() do
          [clause] = quote(do: (unquote(c) -> unquote(v)))
          clause
        end
      end

      def decode_pair(cc) do
        vv = pair_decoder(cc)
        <<vv::size(@puid_bits_per_pair)>>
      end

      def decode_single(c) do
        v = single_decoder(c)
        <<v::size(@puid_bits_per_char)>>
      end
    end
  end
end
