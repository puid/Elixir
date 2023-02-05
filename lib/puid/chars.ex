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

defmodule Puid.Chars do
  @moduledoc """

  Pre-defined character sets for use when creating `Puid` modules.

  ## Example

      iex> defmodule(AlphanumId, do: use(Puid, chars: :alphanum))

  ## Pre-defined Chars

  ### :alpha
  Upper/lower case alphabet

  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
  ```
  bits per character: `5.7`

  ### :alpha_lower
  Lower case alphabet
  ```none
  abcdefghijklmnopqrstuvwxyz
  ```
  bits per character: `4.7`

  ### :alpha_upper
  Upper case alphabet
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZ
  ```
  bits per character: `4.7`

  ### :alphanum
  Upper/lower case alphabet and numbers
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
  ```
  bits per character: `5.95`

  ### :alphanum_lower
  Lower case alphabet and numbers
  ```none
  abcdefghijklmnopqrstuvwxyz0123456789
  ```
  bits per character: `5.17`

  ### :alphanum_upper
  Upper case alphabet and numbers
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
  ```
  bits per character: `5.17`

  ### :base32
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-6) base32 character set
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZ234567
  ```
  bits per character: `5`

  ### :base32_hex
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-7) base32 extended hex character set
  with lowercase letters
  ```none
  0123456789abcdefghijklmnopqrstuv
  ```
  bits per character: `5`

  ### :base32_hex_upper
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-7) base32 extended hex character set
  ```none
  0123456789ABCDEFGHIJKLMNOPQRSTUV
  ```
  bits per character: `5`

  ### :crockford32
  [Crockford 32](https://www.crockford.com/base32.html)
  ```none
  0123456789ABCDEFGHJKMNPQRSTVWXYZ
  ```

  ### :decimal
  Decimal digits
  ```none
  0123456789
  ```
  bits per character: `3.32`

  ### :hex
  Lowercase hexadecimal
  ```none
  0123456789abcdef
  ```
  bits per character: `4`

  ### :hex_upper
  Uppercase hexadecimal
  ```none
  0123456789ABCDEF
  ```
  bits per character: `4`

  ### :safe_ascii
  ASCII characters from `?!` to `?~`, minus backslash, backtick, single-quote and double-quote

  ```none
  `!#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_\abcdefghijklmnopqrstuvwxyz{|}~`
  ```
  bits per character: `6.49`

  ### :safe32
  Strings that don't look like words and are easier to parse visually
  ```none
  2346789bdfghjmnpqrtBDFGHJLMNPQRT
  ```
    - remove all upper and lower case vowels (including y)
    - remove all numbers that look like letters
    - remove all letters that look like numbers
    - remove all letters that have poor distinction between upper and lower case values

  bits per character: `6.49`

  ### :safe64
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-5) file system and URL safe character set
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_
  ```
  bits per character: `6`

  ### :symbol
  :safe_ascii characters not in :alphanum

  ```none
  `!#$%&()*+,-./:;<=>?@[]^_{|}~`
  ```
  bits per character: `4.81`

  """

  @typedoc """
  Chars can be designated by a pre-defined atom, a binary or a charlist
  """
  @type puid_chars() :: atom() | String.t() | charlist()

  @typedoc """
  Character encoding scheme. `:ascii` encoding uses cross-product character pairs.
  """
  @type puid_encoding() :: :ascii | :utf8

  ##
  ## Chars count max is 256 due to optimized bit slicing scheme
  ##
  @chars_count_max 256

  ## -----------------------------------------------------------------------------------------------
  ##  `charlist` of characters
  ## -----------------------------------------------------------------------------------------------
  @doc """
  `charlist` for a pre-defined `Puid.Chars`, a String.t() or a charlist.

  The characters for either String.t() or charlist types must be unique, have more than one
  character, and not be invalid ascii.

  ## Example

      iex> Puid.Chars.charlist(:safe32)
      {:ok, '2346789bdfghjmnpqrtBDFGHJLMNPQRT'}

      iex> Puid.Chars.charlist("dingosky")
      {:ok, 'dingosky'}

      iex> Puid.Chars.charlist("unique")
      {:error, "Characters not unique"}
  """
  @spec charlist(puid_chars()) :: {:ok, charlist()} | Puid.Error.t()
  def charlist(chars) do
    try do
      {:ok, charlist!(chars)}
    rescue
      error in Puid.Error ->
        {:error, error.message()}
    end
  end

  @doc """

  Same as `charlist/1` but either returns __charlist__ or raises a `Puid.Error`

  ## Example

      iex> Puid.Chars.charlist!(:safe32)
      '2346789bdfghjmnpqrtBDFGHJLMNPQRT'

      iex> Puid.Chars.charlist!("dingosky")
      'dingosky'

      iex> Puid.Chars.charlist!("unique")
      # (Puid.Error) Characters not unique
  """
  @spec charlist!(puid_chars()) :: charlist() | Puid.Error.t()
  def charlist!(chars)

  def charlist!(:alpha), do: charlist!(:alpha_upper) ++ charlist!(:alpha_lower)
  def charlist!(:alpha_lower), do: Enum.to_list(?a..?z)
  def charlist!(:alpha_upper), do: Enum.to_list(?A..?Z)
  def charlist!(:alphanum), do: charlist!(:alpha) ++ charlist!(:decimal)
  def charlist!(:alphanum_lower), do: charlist!(:alpha_lower) ++ charlist!(:decimal)
  def charlist!(:alphanum_upper), do: charlist!(:alpha_upper) ++ charlist!(:decimal)
  def charlist!(:base32), do: charlist!(:alpha_upper) ++ '234567'
  def charlist!(:base32_hex), do: charlist!(:decimal) ++ Enum.to_list(?a..?v)
  def charlist!(:base32_hex_upper), do: charlist!(:decimal) ++ Enum.to_list(?A..?V)
  def charlist!(:crockford32), do: charlist!(:decimal) ++ (charlist!(:alpha_upper) -- 'ILOU')
  def charlist!(:decimal), do: Enum.to_list(?0..?9)
  def charlist!(:hex), do: charlist!(:decimal) ++ Enum.to_list(?a..?f)
  def charlist!(:hex_upper), do: charlist!(:decimal) ++ Enum.to_list(?A..?F)
  def charlist!(:safe_ascii), do: ?!..?~ |> Enum.filter(&safe_ascii?(&1))
  def charlist!(:safe32), do: '2346789bdfghjmnpqrtBDFGHJLMNPQRT'

  def charlist!(:safe64),
    do: charlist!(:alpha_upper) ++ charlist!(:alpha_lower) ++ charlist!(:decimal) ++ '-_'

  def charlist!(:symbol) do
    alphanum = charlist!(:alphanum)
    :safe_ascii |> charlist!() |> Enum.filter(&(!Enum.member?(alphanum, &1)))
  end

  def charlist!(charlist) when is_atom(charlist),
    do: raise(Puid.Error, "Invalid pre-defined charlist: :#{charlist}")

  def charlist!(chars) when is_binary(chars),
    do: chars |> to_charlist() |> validate_charlist()

  def charlist!(charlist) when is_list(charlist), do: validate_charlist(charlist)

  @doc false
  @spec encoding(charlist() | binary()) :: puid_encoding()
  def encoding(charlist_or_chars)

  def encoding(chars) when is_binary(chars) do
    chars |> to_charlist() |> encoding()
  end

  def encoding(charlist) when is_list(charlist) do
    charlist
    |> Enum.reduce(:ascii, fn code_point, encoding ->
      cond do
        code_point < 0x007F and safe_ascii?(code_point) ->
          encoding

        safe_code_point?(code_point) ->
          :utf8

        true ->
          raise(Puid.Error, "Invalid char")
      end
    end)
  end

  @doc false
  # Validate that:
  #  - at least 2 code points
  #  - no more than max code points
  #  - unique code points
  #  - valid code points
  def validate_charlist(charlist) when is_list(charlist) do
    len = length(charlist)
    if len < 2, do: raise(Puid.Error, "Need at least 2 characters")

    if @chars_count_max < len,
      do: raise(Puid.Error, "Character count cannot be greater than #{@chars_count_max}")

    if !unique?(charlist, %{}), do: raise(Puid.Error, "Characters not unique")

    charlist
    |> Enum.reduce(true, fn code_point, acc ->
      acc and safe_code_point?(code_point)
    end)
    |> case do
      false ->
        raise(Puid.Error, "Invalid code point")

      _ ->
        charlist
    end
  end

  # Prevent "unsafe" code points
  defp safe_code_point?(cp) when cp < 0x007F, do: safe_ascii?(cp)
  defp safe_code_point?(cp), do: safe_utf8?(cp)

  # Safe ascii code points are chars from ?! to ?~,
  #   omitting backslash, backtick and single/double-quotes
  defp safe_ascii?(cp) when cp < 0x0021, do: false
  defp safe_ascii?(0x0022), do: false
  defp safe_ascii?(0x0027), do: false
  defp safe_ascii?(0x005C), do: false
  defp safe_ascii?(0x0060), do: false
  defp safe_ascii?(cp) when cp < 0x007F, do: true
  defp safe_ascii?(_), do: false

  # Reject code points between tilde and inverse bang
  # CxNote There may be other utf8 code points that should be invalid.
  defp safe_utf8?(g) when g < 0x00A1, do: false
  defp safe_utf8?(_), do: true

  # Are charlist characters unique?
  defp unique?([], no_repeat?), do: no_repeat?

  defp unique?([char | charlist], seen) do
    if seen[char], do: unique?([], false), else: unique?(charlist, seen |> Map.put(char, true))
  end
end
