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
ExUnit.start()

defmodule Puid.Test.FixedBytes do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      @puid_fixed_bytes unquote(opts)[:bytes]
      @puid_n_bytes byte_size(@puid_fixed_bytes)

      def rand_bytes(count) do
        bytes =
          if count <= @puid_n_bytes do
            @puid_fixed_bytes
          else
            pad = 8 * (count - @puid_n_bytes)
            <<@puid_fixed_bytes::binary, 0::size(pad)>>
          end

        byte_offset = Process.get(:fixed_bytes_offset, 0)
        Process.put(:fixed_bytes_offset, byte_offset + count)
        binary_part(bytes, byte_offset, count)
      end

      def reset(), do: Process.put(:fixed_bytes_offset, 0)
    end
  end
end

defmodule Puid.Test.Util do
  @moduledoc false

  use ExUnit.Case

  def binary_digits(bits, group \\ 4) when is_bitstring(bits) and 0 < group,
    do: binary_digits(bits, "", group)

  defp binary_digits(<<>>, digits, group), do: digits |> group_digits(group)

  defp binary_digits(<<0::1, rest::bits>>, digits, group),
    do: binary_digits(<<rest::bits>>, <<digits::binary, ?0>>, group)

  defp binary_digits(<<1::1, rest::bits>>, digits, group),
    do: binary_digits(<<rest::bits>>, <<digits::binary, ?1>>, group)

  defp group_digits(binary_digits, group) do
    group_digits({"", binary_digits}, "", group) |> String.trim()
  end

  defp group_digits({octet, ""}, acc, _group), do: <<acc::binary, " ", octet::binary>>

  defp group_digits({octet, rest}, acc, group),
    do: group_digits(rest |> String.split_at(group), <<acc::binary, " ", octet::binary>>, group)

  def print_bits(bits), do: print_bits(bits, "bits", 4)

  def print_bits(bits, msg) when is_binary(msg), do: print_bits(bits, msg, 4)

  def print_bits(bits, group) when is_integer(group), do: print_bits(bits, "bits", group)

  def print_bits(bits, msg, group) do
    bits |> binary_digits(group) |> IO.inspect(label: msg)
    bits
  end
end
