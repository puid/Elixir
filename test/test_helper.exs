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

defmodule Puid.Test.Util do
  @moduledoc false

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

defmodule Puid.Test.Data do
  @moduledoc false

  use ExUnit.Case, async: true

  def path(file_name), do: Path.join([Path.absname(""), "test", "data", file_name])

  def test_params(data_name) do
    params = File.open!(Puid.Test.Data.path(Path.join(data_name, "params")), [:utf8])
    next_param = fn -> params |> IO.read(:line) |> String.trim_trailing() end

    bin_file = Puid.Test.Data.path(next_param.())
    test_name = next_param.()
    total = String.to_integer(next_param.())
    risk = String.to_float(next_param.())

    chars =
      String.split(next_param.(), ":")
      |> case do
        ["predefined", atom] ->
          String.to_atom(atom)

        ["custom", string] ->
          string
      end

    id_count = String.to_integer(next_param.())

    %{
      bin_file: bin_file,
      test_name: test_name,
      total: total,
      risk: risk,
      chars: chars,
      id_count: id_count
    }
  end

  def data_id_mod(data_name) do
    %{
      :bin_file => bin_file,
      :test_name => test_name,
      :total => total,
      :risk => risk,
      :chars => chars
    } = test_params(data_name)

    data_bytes_mod = "#{test_name}Bytes" |> String.to_atom()

    defmodule(data_bytes_mod,
      do: use(Puid.Test.FixedBytes, data_path: bin_file)
    )

    data_id_mod = "#{test_name}Id" |> String.to_atom()

    defmodule(data_id_mod,
      do:
        use(Puid,
          total: total,
          risk: risk,
          chars: chars,
          rand_bytes: &data_bytes_mod.rand_bytes/1
        )
    )

    data_id_mod
  end

  def test(data_name) do
    data_id_mod = data_id_mod(data_name)

    path(Path.join(data_name, "ids"))
    |> File.stream!()
    |> Stream.map(&String.trim_trailing/1)
    |> Stream.each(fn id -> assert data_id_mod.generate() == id end)
    |> Stream.run()
  end

  def write_test_data(data_name) do
    data_id_mod = Puid.Test.Data.data_id_mod(data_name)

    %{:id_count => id_count} = test_params(data_name)

    ids_file = File.stream!(path(Path.join(data_name, "ids")))

    1..id_count
    |> Stream.map(fn _ -> data_id_mod.generate() end)
    |> Stream.map(&[&1, "\n"])
    |> Enum.into(ids_file)
  end
end
