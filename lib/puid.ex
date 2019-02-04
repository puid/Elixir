# MIT License
#
# Copyright (c) 2019 Knoxen
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

defmodule Puid.Info do
  @moduledoc false
  alias Puid.CharSet

  defstruct chars: CharSet.chars(:safe64),
            charset: :safe64,
            entropy_bits: 128,
            entropy_bits_per_char: 0,
            ere: 0,
            length: 0,
            rand_bytes: nil
end

defmodule Puid.Error do
  @moduledoc """
  Errors raised when defining a Puid module with invalid options
  """
  defexception message: "Puid error"
end

defmodule Puid do
  use Bitwise, only: bsl

  @moduledoc """

  Define modules for the efficient generation of cryptographically strong probably unique
  identifiers (<strong>puid</strong>s, aka random strings) of specified entropy from various
  character sets

  ## Examples

  The simplest usage of `Puid` requires no options. The library adds a `generate/0` function for
  generating **puid**s:

      iex> defmodule(Id, do: use(Puid))
      iex> Id.generate()
      "p3CYi24M8tJNmroTLogO3b"

  By default, `Puid` modules generate **puid**s with at least 128 bits of entropy, making the
  **puid**s suitable replacements for **uuid**s.

  ### Character Set

  The default character set for `Puid` modules is the Base64 URL and file system safe character set
  specified in [RFC 3548](https://tools.ietf.org/html/rfc3548#section-4). Any of the pre-defined
  character sets from `Puid.CharSet` can easily be specified using the `charset` option:

      iex> defmodule(HexId, do: use(Puid, charset: :hex))
      iex> HexId.generate()
      "a60dec6d0b71355aa9579bb46c001700"

  ### Custom Characters

  Any sequence of unique, printable characters can be used to generate **puid**s.

      iex> defmodule(DingoSkyId, do: use(Puid, chars: "dingosky"))
      iex> DingoSkyId.generate()
      "yoisknoydoknkoikgoknynkinoknkygdiikoosksyni"

      iex> defmodule(UnicodeId, do: use(Puid, chars: "ŮήιƈŏδεĊħąŕαсτəř"))
      iex> UnicodeId.generate()
      "αήήδħƈĊŕąąιŏήąŕħƈδəəήιττδδŕąĊδŕι"

  ### Specific Entropy

  #### Bits
  The `bits` option can be used to specify desired entropy bits.

      iex> defmodule Password, do: use Puid, bits: 96, charset: :printable_ascii
      iex> Password.generate()
      "0&pu=w+T#~o)N=E"

  Since the total entropy bits of a **puid** must be a multiple of the entropy bits per character
  used, the actual **puid** `bits` will be equal to or greater than specified. In the example above,
  the entropy bits of a `Password` generated **puid** is actually 98.32.

  #### Total and Risk

  The amount of entropy can be intuitively specified through the `total` and `risk` options. For
  example, to generate a `total` of 10 million **puid**s with a 1 in a quadrillion `risk` of repeat
  using `:safe32` characters:

      iex> defmodule(Safe32Id, do: use(Puid, total: 1.0e7, risk: 1.0e15, charset: :safe32))
      iex> Safe32Id.generate()
      "hjM7md2R9j8D7PNTjBPB"

  The actual `Safe32Id` **puid** entropy bits is 100.

  ### Custom Randomness

  `Puid` generates **puid**s using bytes from the function specified with the `rand_bytes`
  option. If `rand_bytes` is not specified, `Puid` defaults to `:crypto.strong_rand_bytes/1`.

      iex> defmodule(MyRandBytesId, do: use(Puid, bits: 96, charset: :safe32, rand_bytes: &MyRand.bytes/1))
      iex> MyRandBytesId.generate()
      "G2jrmPr3mQPBt2gGB3T4"

  The `MyRand.bytes/1` function must be of the form `(non_neg_integer) -> binary()`

  ### Module Functions

  `Puid` adds the following 2 functions to each created module:

  | Function | Description |
  | -------- | ----------- |
  | generate/0 | function for generating a **puid**  |
  | info/0 | `Puid.Info` struct of module information |

  The `Puid.Info` struct has the following fields:

  | Field | Description |
  | ----- | ----------- |
  | chars | source character set |
  | charset | pre-defined `Puid.Charset` or :custom |
  | entropy_bits | **puid** bits of entropy |
  | entropy_bits_per_char | **puid** entropy bits per character |
  | ere | **puid** entropy representation efficiency |
  | length | **puid** string length |
  | rand_bytes | source function for entropy |

      iex> defmodule(AlphanumId, do: use(Puid, total: 10e06, risk: 1.0e15, charset: :alphanum))
      iex> AlphanumId.info()
      %Puid.Info{
        chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
        charset: :alphanum,
        entropy_bits: 107.18,
        entropy_bits_per_char: 5.95,
        ere: 0.74,
        length: 18,
        rand_bytes: &:crypto.strong_rand_bytes/1
      }
  """

  alias Puid.CharSet
  alias Puid.Info

  import Puid.Entropy

  @doc false
  defmacro __using__(opts) do
    quote do
      import Puid
      import CharSet

      puid_default = %Info{}

      bits = unquote(opts)[:bits]
      total = unquote(opts)[:total]
      risk = unquote(opts)[:risk]

      if !is_nil(total) and is_nil(risk),
        do: raise(Puid.Error, "Must specify risk when specifying total")

      if is_nil(total) and !is_nil(risk),
        do: raise(Puid.Error, "Must specify total when specifying risk")

      puid_bits =
        cond do
          is_nil(bits) and is_nil(total) and is_nil(risk) ->
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

      charset = unquote(opts)[:charset]
      chars = unquote(opts)[:chars]

      {puid_charset, puid_chars} =
        cond do
          is_nil(charset) and is_nil(chars) ->
            {puid_default.charset, puid_default.chars}

          !is_nil(charset) and !is_nil(chars) ->
            raise Puid.Error, "Only one of charset or chars option allowed"

          !is_nil(charset) and is_atom(charset) ->
            case CharSet.chars(charset) do
              :undefined ->
                raise Puid.Error, "Invalid charset: #{charset}"

              chars ->
                {charset, chars}
            end

          !is_nil(charset) ->
            raise Puid.Error, "Invalid charset: #{charset}"

          !is_nil(chars) and is_binary(chars) ->
            if CharSet.unique?(chars) do
              if String.printable?(chars) do
                if String.length(chars) > 1 do
                  {:custom, chars}
                else
                  raise Puid.Error, "Invalid chars: must be more than 1 char"
                end
              else
                raise Puid.Error, "Invalid chars: not printable"
              end
            else
              raise Puid.Error, "Invalid chars: not unique"
            end

          true ->
            raise Puid.Error, "Invalid chars"
        end

      ebpc = puid_chars |> String.length() |> :math.log2()
      puid_len = (puid_bits / ebpc) |> :math.ceil() |> round()
      chars_count = puid_chars |> String.length()
      total_bytes = puid_chars |> String.graphemes() |> Enum.reduce(0, &(byte_size(&1) + &2))
      ere = ebpc * chars_count / 8 / total_bytes |> Float.round(2)

      @puid_charset puid_charset
      @puid_chars puid_chars
      @puid_chars_count chars_count
      @puid_entropy_bits_per_char ebpc
      @puid_len puid_len
      @puid_ere ere

      rand_bytes = unquote(opts[:rand_bytes])

      if !is_nil(rand_bytes) do
        if !is_function(rand_bytes), do: raise(Puid.Error, "rand_bytes not a function")

        if :erlang.fun_info(rand_bytes)[:arity] !== 1,
          do: raise(Puid.Error, "rand_bytes not arity 1")
      end

      @puid_rand_bytes rand_bytes || (&:crypto.strong_rand_bytes/1)

      n_encode_bytes =
        case @puid_charset do
          charset when charset in [:hex, :hex_upper] ->
            (@puid_len / 2) |> round()

          charset when charset in [:base32, :base32_hex, :base32_hex_upper] ->
            (@puid_len * 5 / 8)
            |> :math.floor()
            |> round()

          :safe64 ->
            (@puid_len * 6 / 8)
            |> :math.floor()
            |> round()

          _ ->
            nil
        end

      @puid_n_encode_bytes n_encode_bytes

      if @puid_charset === :custom do
        pow2 = &bsl(1, &1)

        @puid_chars_count
        |> :math.log2()
        |> round()
        |> pow2.()
        |> Kernel.==(@puid_chars_count)
        |> if do
          n_bits =
            @puid_chars_count
            |> :math.log2()
            |> :math.ceil()
            |> round()

          @puid_n_rand_bytes (n_bits * (@puid_len / 8))
                             |> :math.ceil()
                             |> round()
        else
          @puid_n_rand_bytes 0
        end
      end

      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Generate __puid__
      """

      case @puid_charset do
        :custom ->
          if 0 < @puid_n_rand_bytes do
            def generate do
              custom_chars(
                @puid_len,
                @puid_entropy_bits_per_char |> :math.ceil() |> round(),
                0,
                @puid_rand_bytes.(@puid_n_rand_bytes),
                @puid_chars,
                ""
              )
            end
          else
            def generate,
              do:
                custom_chars(
                  @puid_len,
                  @puid_entropy_bits_per_char |> :math.ceil() |> round(),
                  0,
                  @puid_chars_count |> CryptoRand.uniform_bytes(@puid_len, @puid_rand_bytes),
                  @puid_chars,
                  ""
                )
          end

        :alpha ->
          def generate,
            do:
              alpha_chars(
                @puid_len,
                6,
                0,
                CryptoRand.uniform_bytes(52, @puid_len),
                <<>>
              )

        :alpha_lower ->
          def generate,
            do:
              ul_alpha_chars(
                @puid_len,
                5,
                0,
                CryptoRand.uniform_bytes(@puid_chars_count, @puid_len, @puid_rand_bytes),
                ?a,
                ""
              )

        :alpha_upper ->
          def generate,
            do:
              ul_alpha_chars(
                @puid_len,
                5,
                0,
                CryptoRand.uniform_bytes(@puid_chars_count, @puid_len, @puid_rand_bytes),
                ?A,
                ""
              )

        :alphanum ->
          def generate,
            do:
              alphanum_chars(
                @puid_len,
                6,
                0,
                CryptoRand.uniform_bytes(62, @puid_len),
                <<>>
              )

        :alphanum_lower ->
          def generate,
            do:
              ul_alphanum_chars(
                @puid_len,
                6,
                0,
                CryptoRand.uniform_bytes(@puid_chars_count, @puid_len, @puid_rand_bytes),
                ?a,
                ""
              )

        :alphanum_upper ->
          def generate,
            do:
              ul_alphanum_chars(
                @puid_len,
                5,
                0,
                CryptoRand.uniform_bytes(@puid_chars_count, @puid_len, @puid_rand_bytes),
                ?A,
                ""
              )

        :decimal ->
          def generate,
            do:
              decimal_chars(
                @puid_len,
                4,
                0,
                CryptoRand.uniform_bytes(@puid_chars_count, @puid_len, @puid_rand_bytes),
                ""
              )

        :hex ->
          def generate,
            do: @puid_n_encode_bytes |> @puid_rand_bytes.() |> Base.encode16(case: :lower)

        :hex_upper ->
          def generate,
            do: @puid_n_encode_bytes |> @puid_rand_bytes.() |> Base.encode16(case: :upper)

        :base32 ->
          def generate,
            do:
              @puid_n_encode_bytes
              |> @puid_rand_bytes.()
              |> Base.encode32(padding: false)

        :base32_hex ->
          def generate,
            do:
              @puid_n_encode_bytes
              |> @puid_rand_bytes.()
              |> Base.hex_encode32(padding: false, case: :lower)

        :base32_hex_upper ->
          def generate,
            do:
              @puid_n_encode_bytes
              |> @puid_rand_bytes.()
              |> Base.hex_encode32(padding: false, case: :upper)

        :safe32 ->
          def generate,
            do:
              safe32_chars(
                @puid_len,
                5,
                0,
                CryptoRand.uniform_bytes(32, @puid_len, @puid_rand_bytes),
                <<>>
              )

        :safe64 ->
          def generate,
            do:
              @puid_n_encode_bytes
              |> @puid_rand_bytes.()
              |> Base.url_encode64(padding: false)

        :printable_ascii ->
          def generate,
            do:
              printable_ascii_chars(
                @puid_len,
                7,
                0,
                CryptoRand.uniform_bytes(94, @puid_len, @puid_rand_bytes),
                <<>>
              )
      end

      if @puid_charset == :custom do
        @puid_chars
        |> String.graphemes()
        |> Enum.find(&(&1 |> byte_size() > 1))
        |> is_nil()
        |> if do
          defp char_at(ndx), do: @puid_chars |> :binary.part(ndx, 1)
        else
          defp char_at(ndx), do: @puid_chars |> String.at(ndx)
        end

        defp custom_chars(0, _, _, _, _, string), do: string

        defp custom_chars(n, bits, uniform_offset, uniform_bytes, alphabet, string) do
          <<_::size(uniform_offset), ndx::size(bits), _::bits>> = uniform_bytes
          char = char_at(ndx)

          custom_chars(
            n - 1,
            bits,
            uniform_offset + bits,
            uniform_bytes,
            alphabet,
            <<char::binary, string::binary>>
          )
        end
      end

      if @puid_charset == :alpha_lower or @puid_charset == :alpha_upper do
        defp ul_alpha_chars(0, _, _, _, _, string), do: string

        defp ul_alpha_chars(n, bits, uniform_offset, uniform_bytes, char_offset, string) do
          <<_::size(uniform_offset), value::size(bits), _::bits>> = uniform_bytes

          char = char_offset + value

          ul_alpha_chars(
            n - 1,
            bits,
            uniform_offset + bits,
            uniform_bytes,
            char_offset,
            <<char::size(8), string::binary>>
          )
        end
      end

      if @puid_charset == :alpha do
        defp alpha_chars(0, _, _, _, string), do: string

        defp alpha_chars(n, bits, uniform_offset, uniform_bytes, string) do
          <<_::size(uniform_offset), value::size(bits), _::bits>> = uniform_bytes

          char =
            cond do
              value < 26 ->
                ?A + value

              true ->
                ?a + value - 26
            end

          alpha_chars(
            n - 1,
            bits,
            uniform_offset + bits,
            uniform_bytes,
            <<char::size(8), string::binary>>
          )
        end
      end

      if @puid_charset == :alphanum do
        defp alphanum_chars(0, _, _, _, string), do: string

        defp alphanum_chars(n, bits, uniform_offset, uniform_bytes, string) do
          <<_::size(uniform_offset), value::size(bits), _::bits>> = uniform_bytes

          char =
            cond do
              value < 10 ->
                ?0 + value

              value < 36 ->
                ?A + value - 10

              true ->
                ?a + value - 36
            end

          alphanum_chars(
            n - 1,
            bits,
            uniform_offset + bits,
            uniform_bytes,
            <<char::size(8), string::binary>>
          )
        end
      end

      if @puid_charset == :alphanum_lower or @puid_charset == :alphanum_upper do
        defp ul_alphanum_chars(0, _, _, _, _, string), do: string

        defp ul_alphanum_chars(n, bits, uniform_offset, uniform_bytes, char_offset, string) do
          <<_::size(uniform_offset), value::size(bits), _::bits>> = uniform_bytes

          char =
            cond do
              value < 26 ->
                char_offset + value

              true ->
                value - 26 + ?0
            end

          ul_alphanum_chars(
            n - 1,
            bits,
            uniform_offset + bits,
            uniform_bytes,
            char_offset,
            <<char::size(8), string::binary>>
          )
        end
      end

      if @puid_charset == :decimal do
        defp decimal_chars(0, _, _, _, string), do: string

        defp decimal_chars(n, bits, uniform_offset, uniform_bytes, string) do
          <<_::size(uniform_offset), value::size(bits), _::bits>> = uniform_bytes

          char = ?0 + value

          decimal_chars(
            n - 1,
            bits,
            uniform_offset + bits,
            uniform_bytes,
            <<char::size(8), string::binary>>
          )
        end
      end

      # 2 3 4 6 7 8 9 b d f  g  h  j  m  n    p  q  r  t  B  D  F  G  H  J  L  M  N  P  Q  R  T
      # 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14   15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
      # ----- ------- - - ------- -- -----   -------- -- -- -- -------- -- -------- -------- --
      # <3    <7,-3   7 8 <12,-9  12 <15,-13 <18,-15  18 19 20 <24,-21  24 <28,-25  <31,-28  31
      if @puid_charset == :safe32 do
        defp safe32_chars(0, _, _, _, string), do: string

        defp safe32_chars(n, bits, uniform_offset, uniform_bytes, string) do
          <<_::size(uniform_offset), value::size(bits), _::bits>> = uniform_bytes

          char =
            cond do
              value < 3 ->
                ?2 + value

              value < 7 ->
                ?6 + value - 3

              value == 7 ->
                ?b

              value == 8 ->
                ?d

              value < 12 ->
                ?f + value - 9

              value == 12 ->
                ?j

              value < 15 ->
                ?m + value - 13

              value < 18 ->
                ?p + value - 15

              value == 18 ->
                ?t

              value == 19 ->
                ?B

              value == 20 ->
                ?D

              value < 24 ->
                ?F + value - 21

              value == 24 ->
                ?J

              value < 28 ->
                ?L + value - 25

              value < 31 ->
                ?P + value - 28

              value == 31 ->
                ?T
            end

          safe32_chars(
            n - 1,
            bits,
            uniform_offset + bits,
            uniform_bytes,
            <<char::size(8), string::binary>>
          )
        end
      end

      if @puid_charset == :printable_ascii do
        defp printable_ascii_chars(0, _, _, _, string), do: string

        defp printable_ascii_chars(n, bits, uniform_offset, uniform_bytes, string) do
          <<_::size(uniform_offset), value::size(bits), _::bits>> = uniform_bytes

          char = ?! + value

          printable_ascii_chars(
            n - 1,
            bits,
            uniform_offset + bits,
            uniform_bytes,
            <<char::size(8), string::binary>>
          )
        end
      end

      @doc """
      `Puid.Info` module info
      """
      def info,
        do: %Info{
          chars: @puid_chars,
          charset: @puid_charset,
          entropy_bits_per_char: Float.round(@puid_entropy_bits_per_char, 2),
          entropy_bits: Float.round(@puid_len * @puid_entropy_bits_per_char, 2),
          ere: @puid_ere,
          length: @puid_len,
          rand_bytes: @puid_rand_bytes
        }
    end
  end
end
