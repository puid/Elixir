ExUnit.start()

defmodule FixedBytes do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      @puid_fixed_bytes unquote(opts)[:bytes]
      @puid_n_bytes byte_size(@puid_fixed_bytes)

      def rand_bytes(length) do
        bytes =
          if length <= @puid_n_bytes do
            @puid_fixed_bytes
          else
            pad = 8 * (length - @puid_n_bytes)
            <<@puid_fixed_bytes::binary, 0::size(pad)>>
          end

        byte_offset = Process.get(:fixed_bytes_offset, 0)
        Process.put(:fixed_bytes_offset, byte_offset + length)
        binary_part(bytes, byte_offset, length)
      end

      def reset, do: Process.put(:fixed_bytes_offset, 0)
    end
  end

  def binary_digits(bytes) do
    bytes
    |> :binary.bin_to_list()
    |> Enum.map(
      &("~.2B"
        |> :io_lib.format([&1])
        |> to_string()
        |> String.pad_leading(8, ["0"]))
    )
    |> Enum.join(" ")
  end
end
