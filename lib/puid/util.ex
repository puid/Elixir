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

defmodule Puid.Util do
  @moduledoc false

  import Bitwise

  @doc false
  def bit_zero?(n, bit), do: (n &&& 1 <<< (bit - 1)) === 0

  @doc false
  def even?(n), do: bit_zero?(n, 1)

  @doc false
  def log_ceil(n), do: n |> :math.log2() |> r_ceil()

  @doc false
  def pow2(n), do: 1 <<< n

  @doc false
  def pow2?(n), do: n |> :math.log2() |> round() |> pow2() |> Kernel.==(n)

  defp r_ceil(n), do: n |> :math.ceil() |> round()
end

defmodule Puid.Util.FixedBytes do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      fixed_bytes =
        case unquote(opts)[:bytes] do
          nil ->
            File.read!(unquote(opts[:data_path]))

          bytes ->
            bytes
        end

      @agent_name String.to_atom("#{__MODULE__}Agent")
      Agent.start_link(fn -> {0, fixed_bytes} end, name: @agent_name)

      def rand_bytes(count) do
        {byte_offset, fixed_bytes} = state()
        @agent_name |> Agent.update(fn _ -> {byte_offset + count, fixed_bytes} end)
        binary_part(fixed_bytes, byte_offset, count)
      end

      def state(), do: @agent_name |> Agent.get(& &1)

      def reset(), do: @agent_name |> Agent.update(fn {_, fixed_bytes} -> {0, fixed_bytes} end)
    end
  end
end
