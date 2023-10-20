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

defmodule Puid do
  @moduledoc """

  Simple, fast, flexible and efficient generation of probably unique identifiers (`puid`, aka
  random strings) of intuitively specified entropy using pre-defined or custom characters.

  ## Overview

  `Puid` provides fast and efficient generation of random IDs. For the purposes of `Puid`, a random
  ID is considered a random string used in a context of uniqueness, that is, random IDs are a bunch
  of random strings that are hopefully unique.

  Random string generation can be thought of as a _transformation_ of some random source of entropy
  into a string _representation_ of randomness. A general purpose random string library used for
  random IDs should therefore provide user specification for each of the following three key
  aspects:

  ### Entropy source

    What source of randomness is being transformed? `Puid` allows easy specification of the function
    used for source randomness.

  ### ID characters

    What characters are used in the ID? `Puid` provides 16 pre-defined character sets, as well as
    allows custom character designation, including Unicode

  ### ID randomness

    What is the resulting “randomness” of the IDs? Note this isn't necessarily the same as the
    randomness of the entropy source. `Puid` allows explicit specification of ID randomness in an
    intuitive manner.


  ## Examples

  Creating a random ID generator using `Puid` is a simple as:

  ```elixir
  iex> defmodule(RandId, do: use(Puid))
  iex> RandId.generate()
  "8nGA2UaIfaawX-Og61go5A"
  ```

  Options allow easy and complete control of ID generation.

  ### Entropy Source

  `Puid` uses
  [:crypto.strong_rand_bytes/1](https://www.erlang.org/doc/man/crypto.html#strong_rand_bytes-1) as
  the default entropy source. The `rand_bytes` option can be used to specify any function of the
  form `(non_neg_integer) -> binary` as the source:

  ```elixir
  iex > defmodule(PrngPuid, do: use(Puid, rand_bytes: &:rand.bytes/1))
  iex> PrngPuid.generate()
  "bIkrSeU6Yr8_1WHGvO0H3M"
  ```

  ### ID Characters

  By default, `Puid` use the [RFC 4648](https://tools.ietf.org/html/rfc4648#section-5) file system &
  URL safe characters. The `chars` option can by used to specify any of 16 [pre-defined character
  sets](#Chars) or custom characters, including Unicode:

  ```elixir
  iex> defmodule(HexPuid, do: use(Puid, chars: :hex))
  iex> HexPuid.generate()
  "13fb81e35cb89e5daa5649802ad4bbbd"

  iex> defmodule(DingoskyPuid, do: use(Puid, chars: "dingosky"))
  iex> DingoskyPuid.generate()
  "yiidgidnygkgydkodggysonydodndsnkgksgonisnko"

  iex> defmodule(DingoskyUnicodePuid, do: use(Puid, chars: "dîñgø$kyDÎÑGØßK¥", total: 2.5e6, risk: 1.0e15))
  iex> DingoskyUnicodePuid.generate()
  "øßK$ggKñø$dyGîñdyØøØÎîk"

  ```

  ### ID Randomness

  Generated IDs have 128-bit entropy by default. `Puid` provides a simple, intuitive way to specify
  ID randomness by declaring a `total` number of possible IDs with a specified `risk` of a repeat in
  that many IDs:

  To generate up to _10 million_ random IDs with _1 in a trillion_ chance of repeat:

  ```elixir
  iex> defmodule(MyPuid, do: use(Puid, total: 10.0e6, risk: 1.0e15))
  iex> MyPuid.generate()
  "T0bFZadxBYVKs5lA"
  ```

  The `bits` option can be used to directly specify an amount of ID randomness:

  ```elixir
  iex> defmodule(Token, do: use(Puid, bits: 256, chars: :hex_upper))
  iex> Token.generate()
  "6E908C2A1AA7BF101E7041338D43B87266AFA73734F423B6C3C3A17599F40F2A"
  ```

  ## Module API

  `Puid` modules have two functions:

  ```elixir
  iex> defmodule(AlphanumId, do: use(Puid, total: 10.0e06, risk: 1.0e15, chars: :alphanum))
  ```

  **`generate/0`**

  Generates a **`puid`**

  ```elixir
  iex> AlphanumId.generate()
  "UKQHTmvASwyhcwGNA"
  ```

  **`info/0`**

    Returns a `Puid.Info` structure consisting of

    - Name of pre-defined `Puid.Chars` or `:custom`
    - Source characters
    - Entropy bits
      - May be larger than the specified `bits` since it is a multiple of the entropy bits per
        character
    - Entropy bits per character
    - Entropy representation efficiency
      - Ratio of the **`puid`** entropy to the bits required for string representation
    - **`puid`** string length
    - Entropy source function

  ```elixir
  iex> AlphanumId.info()
   %Puid.Info{
     char_set: :alphanum,
     characters: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
     entropy_bits: 101.22,
     entropy_bits_per_char: 5.95,
     ere: 0.74,
     length: 17,
     rand_bytes: &:crypto.strong_rand_bytes/1
   }
  ```
  """

  import Puid.Entropy
  import Puid.Util

  @doc false
  defmacro __using__(opts) do
    quote do
      import Bitwise

      alias Puid.Chars

      puid_default = %Puid.Info{}

      chars = unquote(opts)[:chars]

      bits = unquote(opts)[:bits]
      risk = unquote(opts)[:risk]
      total = unquote(opts)[:total]

      {puid_charlist, puid_char_set} =
        if is_nil(chars) do
          {puid_default.characters |> to_charlist(), puid_default.char_set}
        else
          charlist = Chars.charlist!(chars)
          if is_atom(chars), do: {charlist, chars}, else: {charlist, :custom}
        end

      chars_encoding = Chars.encoding(puid_charlist)

      if !is_nil(total) and is_nil(risk),
        do: raise(Puid.Error, "Must specify risk when specifying total")

      if is_nil(total) and !is_nil(risk),
        do: raise(Puid.Error, "Must specify total when specifying risk")

      entropy_bits =
        cond do
          is_nil(bits) and is_nil(total) ->
            puid_default.entropy_bits

          is_number(bits) and bits < 1 ->
            raise Puid.Error, "Invalid bits. Must be greater than 1"

          is_number(bits) ->
            bits

          !is_nil(bits) ->
            raise Puid.Error, "Invalid bits. Must be numeric"

          true ->
            bits(total, risk)
        end

      rand_bytes = unquote(opts[:rand_bytes]) || (&:crypto.strong_rand_bytes/1)

      if !is_function(rand_bytes), do: raise(Puid.Error, "rand_bytes not a function")

      if :erlang.fun_info(rand_bytes)[:arity] !== 1,
        do: raise(Puid.Error, "rand_bytes not arity 1")

      chars_count = length(puid_charlist)
      ebpc = :math.log2(chars_count)
      puid_len = (entropy_bits / ebpc) |> :math.ceil() |> round()

      avg_rep_bits_per_char =
        puid_charlist
        |> to_string()
        |> byte_size()
        |> Kernel.*(8)
        |> Kernel./(chars_count)

      ere = (ebpc / avg_rep_bits_per_char) |> Float.round(2)

      bits_per_char = log_ceil(chars_count)

      defmodule __MODULE__.Bits,
        do:
          use(Puid.Bits,
            chars_count: chars_count,
            puid_len: puid_len,
            rand_bytes: rand_bytes
          )

      if chars_encoding == :ascii do
        defmodule __MODULE__.Encoding,
          do:
            use(Puid.Encoding.ASCII,
              charlist: puid_charlist,
              bits_per_char: bits_per_char,
              puid_len: puid_len
            )
      else
        defmodule __MODULE__.Encoding,
          do:
            use(Puid.Encoding.Utf8,
              charlist: puid_charlist,
              bits_per_char: bits_per_char,
              puid_len: puid_len
            )
      end

      @doc """
      Generate a `puid`
      """
      def generate(), do: __MODULE__.Bits.generate() |> __MODULE__.Encoding.encode()

      @entropy_bits ebpc * puid_len

      @doc """
      Approximation of `total` possible `puid`s which can be generated at the specified `risk`
      """
      def total(risk), do: round(Puid.Entropy.total(@entropy_bits, risk))

      @doc """
      Approximation of `risk` in genertating `total` `puid`s
      """
      def risk(total), do: round(Puid.Entropy.risk(@entropy_bits, total))

      mod_info = %Puid.Info{
        characters: puid_charlist |> to_string(),
        char_set: puid_char_set,
        entropy_bits_per_char: Float.round(ebpc, 2),
        entropy_bits: Float.round(@entropy_bits, 2),
        ere: ere,
        length: puid_len,
        rand_bytes: rand_bytes
      }

      @puid_mod_info mod_info

      @doc """
      `Puid.Info` module info
      """
      def info, do: @puid_mod_info
    end
  end
end
