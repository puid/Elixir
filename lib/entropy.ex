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

defmodule Puid.Entropy do
  @moduledoc """
  [Entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory)) related calculations

  The implementation is based on mathematical approximations to the solution of what is often
  referred to as the [Birthday
  Problem](https://en.wikipedia.org/wiki/Birthday_problem#Calculating_the_probability).

  """

  alias Puid.CharSet

  @doc """
  Entropy bits for generating a `total` number of instances with the given `risk` of repeat

  The total size of the instance pool is 2<sup>bits</sup>.

  ## Example

      iex> Puid.Entropy.bits(10.0e6, 1.0e12)
      85.37013046707142

  """
  @spec bits(pos_integer, pos_integer) :: float()
  def bits(1, _), do: 0

  def bits(_, 1), do: 0

  def bits(total, risk) when is_number(total) and is_number(risk) do
    n =
      cond do
        total < 1000 ->
          :math.log2(total) + :math.log2(total - 1)

        true ->
          2 * :math.log2(total)
      end

    n + :math.log2(risk) - 1
  end

  @doc """

  Entropy bits of a string of `len` generated from characters `charset`, where `charset` is
  either an pre-defined `Puid.CharSet` or a string of unique characters.

  The character set must be comprised of unique symbols, and it is assumed each symbol in the
  character set has equal probability of occurrence (which maximizes entropy).

  ## Example

      iex> Puid.Entropy.bits_for_len(14, :alphanum)
      {:ok, 83}

      iex> Puid.Entropy.bits_for_len(14, "dingosky")
      {:ok, 42}

  """
  @spec bits_for_len(non_neg_integer(), atom() | String.t()) ::
          {:ok, non_neg_integer()} | {:error, Puid.reason()}

  def bits_for_len(len, charset) when -1 < len and (is_atom(charset) or is_binary(charset)) do
    case bits_per_char(charset) do
      {:ok, ebpc} ->
        {:ok, (len * ebpc) |> trunc()}

      error ->
        error
    end
  end

  @doc """

  Same as `Puid.Entropy.bits_for_len/2` but either returns the integer __bits__ or raises a
  `Puid.Error`

  ## Example

      iex> Puid.Entropy.bits_for_len!(14, :alphanum)
      83

      iex> Puid.Entropy.bits_for_len!(14, "dingosky")
      42

  """
  @spec bits_for_len!(non_neg_integer(), atom() | String.t()) :: non_neg_integer()
  def bits_for_len!(len, charset) when -1 < len and (is_atom(charset) or is_binary(charset)) do
    case(bits_for_len(len, charset)) do
      {:ok, ebpc} ->
        ebpc

      {:error, reason} ->
        raise Puid.Error, reason
    end
  end

  @doc """

  Entropy bits per character where `charset` is either an pre-defined `Puid.CharSet` or a string of
  unique characters.

  The character set must be comprised of unique symbols, and it is assumed each symbol in the
  character set has equal probability of occurrence (which maximizes entropy).

  Returns `{:ok, bits}`; or `{:error, reason}` if `arg` is either an unrecognized pre-defined
  `Puid.CharSet` or a string of non-unique characters.

  ## Example

      iex> Puid.Entropy.bits_per_char(:alphanum)
      {:ok, 5.954196310386875}

      iex> Puid.Entropy.bits_per_char("dingosky")
      {:ok, 3.0}

  """
  @spec bits_per_char(atom() | String.t()) :: {:ok, float()} | {:error, Puid.reason()}
  def bits_per_char(charset)

  def bits_per_char(charset) when is_atom(charset) do
    case CharSet.chars(charset) do
      :undefined ->
        {:error, "Invalid: charset not recognized"}

      chars ->
        {:ok, ebpc(chars)}
    end
  end

  def bits_per_char(chars) when is_binary(chars) do
    if CharSet.unique?(chars),
      do: {:ok, ebpc(chars)},
      else: {:error, "Invalid: chars not unique"}
  end

  @doc """
  Same as `bits_per_char/1` but either returns the `bits` or raises a `Puid.Error`

  ## Example

       iex> Puid.Entropy.bits_per_char!(:alphanum)
       5.954196310386875

       Puid.Entropy.bits_per_char!("dingosky")
       3.0

  """
  @spec bits_per_char!(atom() | String.t()) :: float()
  def bits_per_char!(charset)

  def bits_per_char!(arg) do
    case bits_per_char(arg) do
      {:ok, ebpc} ->
        ebpc

      {:error, reason} ->
        raise Puid.Error, reason
    end
  end

  defp ebpc(chars) do
    chars |> String.length() |> :math.log2()
  end

  @doc """

  Length needed for a string generated from `charset` to have `bits` of entropy.

  The character set must be comprised of unique symbols, and it is assumed each symbol in the
  character set has equal probability of occurrence (which maximizes entropy).

  ## Example

      iex> Puid.Entropy.len_for_bits(128, :alphanum)
      {:ok, 22}

      iex> Puid.Entropy.len_for_bits(128, "dingosky")
      {:ok, 43}

  """
  @spec len_for_bits(non_neg_integer(), atom() | String.t()) ::
          {:ok, non_neg_integer()} | {:error, Puid.reason()}
  def len_for_bits(bits, charset) when -1 < bits and (is_atom(charset) or is_binary(charset)) do
    case bits_per_char(charset) do
      {:ok, ebpc} ->
        {:ok, (bits / ebpc) |> :math.ceil() |> round()}

      error ->
        error
    end
  end

  @doc """

  Same as `Puid.Entropy.len_for_bits/2` but either returns the integer __len__ or raises a
  `Puid.Error`

  ## Example

      iex> Puid.Entropy.len_for_bits!(128, :alphanum)
      22

      iex> Puid.Entropy.len_for_bits!(128, "dingosky")
      43

  """
  @spec len_for_bits!(non_neg_integer(), atom() | String.t()) :: non_neg_integer()
  def len_for_bits!(bits, charset) when -1 < bits and (is_atom(charset) or is_binary(charset)) do
    case len_for_bits(bits, charset) do
      {:ok, len} ->
        len

      {:error, reason} ->
        raise Puid.Error, reason
    end
  end
end
