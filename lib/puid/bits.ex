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

defmodule Puid.Bits do
  @moduledoc false

  import Bitwise
  import Puid.Util

  defmacro __using__(opts) do
    quote do
      chars_count = unquote(opts[:chars_count])
      puid_len = unquote(opts)[:puid_len]
      rand_bytes = unquote(opts)[:rand_bytes]

      bits_per_char = log_ceil(chars_count)
      bits_per_puid = puid_len * bits_per_char
      bytes_per_puid = trunc(:math.ceil(bits_per_puid / 8))

      base_value = if even?(chars_count), do: chars_count - 1, else: chars_count
      base_shift = {base_value, bits_per_char}

      bit_shifts =
        if pow2?(chars_count) do
          [base_shift]
        else
          (bits_per_char - 1)..2
          |> Enum.reduce(
            [],
            fn bit, shifts ->
              if bit_zero?(base_value, bit) do
                [{base_value ||| pow2(bit) - 1, bits_per_char - bit + 1} | shifts]
              else
                shifts
              end
            end
          )
          |> List.insert_at(0, base_shift)
        end

      # |> IO.inspect(label: "bit_shifts")

      {:module, mod} = rand_bytes |> Function.info(:module)
      {:name, name} = rand_bytes |> Function.info(:name)

      @puid_carried_bits String.to_atom("#{mod}_#{name}_puid_carried_bits")
      @puid_bit_shifts bit_shifts
      @puid_bits_per_char bits_per_char
      @puid_bits_per_puid bits_per_puid
      @puid_bytes_per_puid bytes_per_puid
      @puid_char_count chars_count
      @puid_len puid_len
      @puid_rand_bytes rand_bytes

      # If chars count is a power of 2, sliced bits always yield a valid char
      is_pow2? = pow2?(chars_count)

      @spec generate() :: bitstring()
      def generate()

      cond do
        is_pow2? and rem(bits_per_puid, 8) == 0 ->
          # Sliced bits always valid and no carried bits
          def generate(), do: @puid_rand_bytes.(@puid_bytes_per_puid)

        is_pow2? ->
          # Sliced bits always valid with carried bits
          def generate() do
            carried_bits = Process.get(@puid_carried_bits, <<>>)

            <<puid_bits::size(@puid_bits_per_puid), unused_bits::bits>> =
              generate_bits(@puid_len, carried_bits)

            Process.put(@puid_carried_bits, unused_bits)

            <<puid_bits::size(@puid_bits_per_puid)>>
          end

        true ->
          # Always manage carried bits since bit slices can be rejected with variable shift
          def generate(),
            do: generate(@puid_len, Process.get(@puid_carried_bits, <<>>), <<>>)

          defp generate(0, unused_bits, puid_bits) do
            Process.put(@puid_carried_bits, unused_bits)
            puid_bits
          end

          defp generate(char_count, carried_bits, puid_bits) do
            bits = generate_bits(char_count, carried_bits)

            {sliced_count, unused_bits, acc_bits} = slice(char_count, 0, bits, puid_bits)

            generate(char_count - sliced_count, unused_bits, acc_bits)
          end
      end

      @spec reset() :: no_return()
      def reset(),
        do: Process.put(@puid_carried_bits, <<>>)

      defp generate_bits(char_count, carried_bits) do
        num_bits_needed = char_count * @puid_bits_per_char - bit_size(carried_bits)

        if num_bits_needed <= 0 do
          carried_bits
        else
          new_bytes =
            (num_bits_needed / 8)
            |> :math.ceil()
            |> round()
            |> @puid_rand_bytes.()

          <<carried_bits::bits, new_bytes::bytes>>
        end
      end

      defp slice(0, sliced, bits, acc_bits),
        do: {sliced, bits, acc_bits}

      defp slice(count, sliced, bits, acc_bits) do
        <<value::@puid_bits_per_char, _rest::bits>> = bits

        if value < @puid_char_count do
          <<_used::@puid_bits_per_char, rest::bits>> = bits

          # IO.puts("accept #{value}")

          slice(
            count - 1,
            sliced + 1,
            <<rest::bits>>,
            <<acc_bits::bits, value::size(@puid_bits_per_char)>>
          )
        else
          {_, bit_shift} =
            @puid_bit_shifts
            |> Enum.find(fn {shift_value, _} -> value <= shift_value end)

          # IO.puts("reject #{value} --> #{bit_shift}")

          <<_used::size(bit_shift), rest::bits>> = bits

          slice(
            count - 1,
            sliced,
            <<rest::bits>>,
            <<acc_bits::bits>>
          )
        end
      end
    end
  end
end
