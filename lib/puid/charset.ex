# MIT License
#
# Copyright (c) 2018 Knoxen
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

defmodule Puid.CharSet do
  @moduledoc """

  Pre-defined `Puid.CharSet`s are specified via an atom `charset` option during `Puid` module
  definition.

  ## Example

      iex> defmodule(AlphanumId, do: use(Puid, charset: :alphanum))

  ## Pre-defined CharSets

  ### :alpha
  Upper/lower case alphabet
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
  ```

  ### :alpha_lower
  Lower case alphabet
  ```none
  abcdefghijklmnopqrstuvwxyz
  ```

  ### :alpha_upper
  Upper case alphabet
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZ
  ```

  ### :alphanum
  Upper/lower case alphabet and numbers
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
  ```

  ### :alphanum_lower
  Lower case alphabet and numbers
  ```none
  abcdefghijklmnopqrstuvwxyz0123456789
  ```

  ### :alphanum_upper
  Upper case alphabet and numbers
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
  ```

  ### :base32
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-6) base32 character set
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZ234567
  ```

  ### :base32_hex
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-7) base32 extended hex character set
  with lowercase letters
  ```none
  0123456789abcdefghijklmnopqrstuv
  ```

  ### :base32_hex_upper
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-7) base32 extended hex character set
  ```none
  0123456789ABCDEFGHIJKLMNOPQRSTUV
  ```

  ### :decimal
  Decimal digits
  ```none
  0123456789
  ```

  ### :hex
  Lowercase hexidecimal
  ```none
  0123456789abcdef
  ```

  ### :hex_upper
  Uppercase hexidecimal
  ```none
  0123456789ABCDEF
  ```

  ### :safe32
  Strings that don't look like English words and are easy to parse visually
  ```none
  2346789bdfghjmnpqrtBDFGHJLMNPQRT
  ```
    - remove all upper and lower case vowels (including y)
    - remove all numbers that look like letters
    - remove all letters that look like numbers
    - remove all letters that have poor distinction between upper and lower case values

  ### :safe64
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-5) file system and URL safe character set
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_
  ```

  ### :printable_ascii
  Printable ASCII characters from `?!` to `?~`
  ```none
  `!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\`abcdefghijklmnopqrstuvwxyz{|}~`
  ```
  """

  @doc false
  def unique?(chars) when is_binary(chars), do: unique?(chars, true)

  defp unique?("", unique), do: unique

  defp unique?(_, false), do: false

  defp unique?(chars, true) do
    {char, rest} = chars |> String.next_grapheme()
    unique?(rest, rest |> String.contains?(char) |> Kernel.!())
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Characters for charset
  ## -----------------------------------------------------------------------------------------------
  @doc """
  Return pre-defined `Puid.CharSet` characters or `:undefined`

  ## Example

      iex> Puid.CharSet.chars(:safe32)
      "2346789bdfghjmnpqrtBDFGHJLMNPQRT"

      iex> Puid.CharSet.chars(:dne)
      :undefined
  """
  @spec chars(atom()) :: String.t() | :undefined
  def chars(charset)

  def chars(:alpha), do: chars(:alpha_upper) <> chars(:alpha_lower)
  def chars(:alpha_lower), do: "abcdefghijklmnopqrstuvwxyz"
  def chars(:alpha_upper), do: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  def chars(:alphanum), do: chars(:alpha) <> chars(:decimal)
  def chars(:alphanum_lower), do: chars(:alpha_lower) <> chars(:decimal)
  def chars(:alphanum_upper), do: chars(:alpha_upper) <> chars(:decimal)
  def chars(:base32), do: chars(:alpha_upper) <> "234567"
  def chars(:base32_hex), do: chars(:decimal) <> "abcdefghijklmnopqrstuv"
  def chars(:base32_hex_upper), do: chars(:decimal) <> "ABCDEFGHIJKLMNOPQRSTUV"
  def chars(:decimal), do: "0123456789"
  def chars(:hex), do: chars(:decimal) <> "abcdef"
  def chars(:hex_upper), do: chars(:decimal) <> "ABCDEF"
  def chars(:printable_ascii), do: ?!..?~ |> Enum.to_list() |> to_string()
  def chars(:safe32), do: "2346789bdfghjmnpqrtBDFGHJLMNPQRT"
  def chars(:safe64), do: chars(:alpha_upper) <> chars(:alpha_lower) <> chars(:decimal) <> "-_"
  def chars(_), do: :undefined
end
