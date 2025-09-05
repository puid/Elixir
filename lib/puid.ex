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

  Module functions:

  - **generate/0**: Generate a random **puid**
  - **total/1**: total **puid**s which can be generated at a specified `risk`
  - **risk/1**: risk of generating `total` **puid**s
  - **encode/1**: Encode `bytes` into a **puid**
  - **decode/1**: Decode a `puid` into **bytes**
  - **info/0**: Module information

  The `total/1`, `risk/1` functions provide approximations to the **risk** of a repeat in some **total** number of generated **puid**s. The mathematical approximations used purposely _overestimate_ **risk** and _underestimate_ **total**.

  The `encode/1`, `decode/1` functions convert **puid**s to and from **bits** to facilitate binary data storage, e.g. as an **Ecto** type. Note that for efficiency `Puid` operates at a bit level, so `decode/1` of a **puid** produces _representative_ bytes such that `encode/1` of those **bytes** produces the same **puid**. The **bytes** are the **puid** specific _bitstring_ with 0 bit values appended to the ending byte boundary.

  The `info/0` function returns a `Puid.Info` structure consisting of:

  - source characters
  - name of pre-defined `Puid.Chars` or `:custom`
  - entropy bits per character
  - total entropy bits
      - may be larger than the specified `bits` since it is a multiple of the entropy bits per character
  - entropy representation efficiency
      - ratio of the **puid** entropy to the bits required for **puid** string representation
  - entropy transform efficiency
      - ratio of **puid** entropy bits to avg entropy source bits required for ID generation
  - entropy source function
  - **puid** string length

  #### Example

  ```elixir
  iex> defmodule(SafeId, do: use(Puid))

  iex> SafeId.generate()
  "CSWEPL3AiethdYFlCbSaVC"

  iex> SafeId.total(1_000_000)
  104350568690606000

  iex> SafeId.risk(1.0e12)
  9007199254740992

  iex> SafeId.decode("CSWEPL3AiethdYFlCbSaVC")
  <<9, 37, 132, 60, 189, 192, 137, 235, 97, 117, 129, 101, 9, 180, 154, 84, 32>>

  iex> SafeId.encode(<<9, 37, 132, 60, 189, 192, 137, 235, 97, 117, 129, 101, 9, 180, 154, 84, 32>>)
  "CSWEPL3AiethdYFlCbSaVC"

  iex> SafeId.info()
  %Puid.Info{
  characters: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
  char_set: :safe64,
  entropy_bits: 132.0,
  entropy_bits_per_char: 6.0,
  ere: 0.75,
  length: 22,
  rand_bytes: &:crypto.strong_rand_bytes/1
  }
  ```

  """

  import Puid.Entropy
  import Puid.Util

  @type t :: binary

  @doc false
  defmacro __using__(opts) do
    quote do
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
      entropy_bits_per_char = :math.log2(chars_count)
      puid_len = (entropy_bits / entropy_bits_per_char) |> :math.ceil() |> round()

      metrics_charset =
        if is_atom(puid_char_set) and puid_char_set != :custom do
          puid_char_set
        else
          puid_charlist
        end

      metrics = Puid.Chars.metrics(metrics_charset)
      ere = metrics.ere |> Float.round(2)
      ete = metrics.ete |> Float.round(2)

      puid_bits_per_char = log_ceil(chars_count)

      @entropy_bits entropy_bits_per_char * puid_len
      @bits_per_puid puid_len * puid_bits_per_char
      @puid_len puid_len

      defmodule __MODULE__.Bits,
        do:
          use(Puid.Bits,
            chars_count: chars_count,
            puid_len: puid_len,
            rand_bytes: rand_bytes
          )

      if chars_encoding == :ascii do
        defmodule __MODULE__.Encoder,
          do:
            use(Puid.Encoder.ASCII,
              charlist: puid_charlist,
              bits_per_char: puid_bits_per_char,
              puid_len: puid_len
            )

        defmodule __MODULE__.Decoder,
          do:
            use(Puid.Decoder.ASCII,
              charlist: puid_charlist,
              puid_len: puid_len
            )
      else
        defmodule __MODULE__.Encoder,
          do:
            use(Puid.Encoder.Utf8,
              charlist: puid_charlist,
              bits_per_char: puid_bits_per_char,
              puid_len: puid_len
            )
      end

      @doc """
      Generate a `puid`
      """
      @spec generate() :: String.t()
      def generate(),
        do: __MODULE__.Bits.generate() |> __MODULE__.Encoder.encode()

      @doc """
      Encode `bits` into a `puid`.

      `bits` must contain enough bits to create a `puid`. The rest are ignored.
      """
      @spec encode(bits :: bitstring()) :: String.t() | {:error, String.t()}
      def encode(bits)

      def encode(<<_::size(@bits_per_puid)>> = bits) do
        __MODULE__.Encoder.encode(bits)
      rescue
        _ ->
          {:error, "unable to encode"}
      end

      def encode(_),
        do: {:error, "unable to encode"}

      @doc """
      Decode `puid` into representative `bits`.

      `puid` must a representative **puid** from this module.

      NOTE: `decode/1` is not supported for non-ascii character sets
      """
      @spec decode(puid :: String.t()) :: bitstring() | {:error, String.t()}
      def decode(puid)

      if chars_encoding == :ascii do
        def decode(puid),
          do: __MODULE__.Decoder.decode(puid)
      else
        def decode(_),
          do: {:error, "not supported for non-ascii characters sets"}
      end

      @doc """
      Approximate **total** possible **puid**s at a specified `risk`
      """
      @spec total(risk :: float()) :: integer()
      def total(risk),
        do: round(Puid.Entropy.total(@entropy_bits, risk))

      @doc """
      Approximate **risk** in generating `total` **puid**s
      """
      @spec risk(total :: float()) :: integer()
      def risk(total),
        do: round(Puid.Entropy.risk(@entropy_bits, total))

      mod_info = %Puid.Info{
        characters: puid_charlist |> to_string(),
        char_set: puid_char_set,
        entropy_bits_per_char: Float.round(entropy_bits_per_char, 2),
        entropy_bits: Float.round(@entropy_bits, 2),
        ere: ere,
        ete: ete,
        length: puid_len,
        rand_bytes: rand_bytes
      }

      @puid_mod_info mod_info

      @doc """
      `Puid.Info` module info
      """
      @spec info() :: Puid.Info.t()
      def info(),
        do: @puid_mod_info
    end
  end
end
