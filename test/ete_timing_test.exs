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
defmodule Puid.Test.ETETiming do
  use ExUnit.Case

  def time(function, label) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
    |> IO.inspect(label: label)
  end

  defp format_ratio(ratio) do
    :io_lib.format("~.1f", [ratio])
    |> IO.iodata_to_binary()
  end

  defp report_interval_speed(interval_time, bit_shift_time) do
    cond do
      interval_time < bit_shift_time ->
        ratio = format_ratio(bit_shift_time / interval_time)
        IO.puts("    interval is ~#{ratio}× faster than bit_shift")

      interval_time > bit_shift_time ->
        ratio = format_ratio(interval_time / bit_shift_time)
        IO.puts("    interval is ~#{ratio}× slower than bit_shift")

      true ->
        IO.puts("    interval is ~1.0× as fast as bit_shift")
    end
  end

  defp module_name(charset, sampler, source) do
    charset_key = Atom.to_string(charset)
    charset_name = Macro.camelize(charset_key)
    charset_hash = :erlang.phash2(charset_key)
    sampler_name = sampler |> Atom.to_string() |> Macro.camelize()
    source_name = source |> Atom.to_string() |> Macro.camelize()
    Module.concat([__MODULE__, "#{charset_name}#{charset_hash}#{sampler_name}#{source_name}"])
  end

  defp redefine(module_name, quoted) do
    case Code.ensure_loaded?(module_name) do
      true ->
        :code.purge(module_name)
        :code.delete(module_name)

      false ->
        :ok
    end

    Module.create(module_name, quoted, Macro.Env.location(__ENV__))
  end

  defp define_id_module(charset, sampler, source, bits) do
    module = module_name(charset, sampler, source)

    rand_bytes =
      case source do
        :prng -> &:rand.bytes/1
        :csprng -> &:crypto.strong_rand_bytes/1
      end

    redefine(
      module,
      quote do
        use Puid,
          bits: unquote(bits),
          chars: unquote(charset),
          sampler: unquote(sampler),
          rand_bytes: unquote(rand_bytes)
      end
    )

    module
  end

  defp generator(module, trials) do
    fn ->
      for _ <- 1..trials do
        apply(module, :generate, [])
      end
    end
  end

  defp remove_modules(modules) do
    Enum.each(modules, fn module ->
      :code.purge(module)
      :code.delete(module)
    end)
  end

  defp usable_charset?(charset) do
    try do
      _ = charset |> Puid.Chars.charlist!() |> Puid.Chars.encoding()
      true
    rescue
      _ -> false
    end
  end

  @tag :timing
  @tag :ete_timing
  @tag timeout: 300_000
  test "compare bit_shift and interval timing" do
    trials = 50_000
    bits = 128
    charsets = Puid.Chars.predefined() |> Enum.sort_by(&Atom.to_string/1)

    IO.puts("\n--- ETE Sampler Timing ---")
    IO.puts("\n  Generate #{trials} random IDs at #{bits} bits of entropy")
    IO.puts("  Character sets: #{length(charsets)} (dynamic from Puid.Chars.predefined/0)")

    Enum.each(charsets, fn charset ->
      case usable_charset?(charset) do
        true ->
          bit_shift_prng = define_id_module(charset, :bit_shift, :prng, bits)
          interval_prng = define_id_module(charset, :interval, :prng, bits)
          bit_shift_csprng = define_id_module(charset, :bit_shift, :csprng, bits)
          interval_csprng = define_id_module(charset, :interval, :csprng, bits)

          assert apply(bit_shift_prng, :info, []).length == apply(interval_prng, :info, []).length

          assert apply(bit_shift_csprng, :info, []).length ==
                   apply(interval_csprng, :info, []).length

          IO.puts("\n  Charset: #{charset}")
          IO.puts("")

          :rand.seed(:exsss)
          bit_shift_prng_time = time(generator(bit_shift_prng, trials), "    bit_shift (PRNG)   ")
          interval_prng_time = time(generator(interval_prng, trials), "    interval  (PRNG)   ")
          report_interval_speed(interval_prng_time, bit_shift_prng_time)

          IO.puts("")
          :crypto.rand_seed()

          bit_shift_csprng_time =
            time(generator(bit_shift_csprng, trials), "    bit_shift (CSPRNG) ")

          interval_csprng_time =
            time(generator(interval_csprng, trials), "    interval  (CSPRNG) ")

          report_interval_speed(interval_csprng_time, bit_shift_csprng_time)

          remove_modules([bit_shift_prng, interval_prng, bit_shift_csprng, interval_csprng])

        false ->
          IO.puts("\n  Charset: #{charset} (skipped: not valid for use(Puid, chars: ...))")
      end
    end)
  end
end
