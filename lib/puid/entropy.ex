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

defmodule Puid.Entropy do
  @moduledoc """
  [Entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory)) related calculations

  The implementation is based on mathematical approximations to the solution of what is often
  referred to as the [Birthday
  Problem](https://en.wikipedia.org/wiki/Birthday_problem#Calculating_the_probability).

  """

  @type puid_chars :: Puid.Chars.puid_chars()

  @doc """
  Entropy bits for generating a `total` number of events with the given `risk` of repeat

  The total size of the event pool is 2<sup>bits</sup>.

  ## Example

      iex> Puid.Entropy.bits(10.0e6, 1.0e12)
      85.37013046707142

  """
  @spec bits(non_neg_integer(), non_neg_integer()) :: float()
  def bits(0, _), do: 0
  def bits(1, _), do: 0

  def bits(_, 0), do: 0
  def bits(_, 1), do: 0

  def bits(total, risk) do
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
  Entropy bits per `chars` character.

  `chars` must be valid as per `Chars.charlist/1`.

  ## Example

      iex> Puid.Entropy.bits_per_char(:alphanum)
      {:ok, 5.954196310386875}

      iex> Puid.Entropy.bits_per_char("dingosky")
      {:ok, 3.0}

  """
  @spec bits_per_char(puid_chars()) :: {:ok, float()} | Puid.Error.t()
  def bits_per_char(chars) do
    with {:ok, charlist} <- chars |> Puid.Chars.charlist() do
      {:ok, charlist |> length() |> :math.log2()}
    else
      error ->
        error
    end
  end

  @doc """
  Same as `bits_per_char/1` but either returns __bits__ or raises a `Puid.Error`

  ## Example

       iex> Puid.Entropy.bits_per_char!(:alphanum)
       5.954196310386875

       Puid.Entropy.bits_per_char!("dingosky")
       3.0

  """
  @spec bits_per_char!(puid_chars()) :: float()
  def bits_per_char!(chars) do
    with {:ok, ebpc} <- bits_per_char(chars) do
      ebpc
    else
      {:error, reason} ->
        raise(Puid.Error, reason)
    end
  end

  @doc """
  Entropy bits for a binary of length `len` comprised of `chars` characters.

  `chars` must be valid as per `Chars.charlist/1`.

  ## Example

      iex> Puid.Entropy.bits_for_len(:alphanum, 14)
      {:ok, 83}

      iex> Puid.Entropy.bits_for_len('dingosky', 14)
      {:ok, 42}

  """
  @spec bits_for_len(puid_chars(), non_neg_integer()) :: {:ok, non_neg_integer()} | Puid.Error.t()
  def bits_for_len(chars, len) do
    with {:ok, ebpc} <- bits_per_char(chars) do
      {:ok, (len * ebpc) |> trunc()}
    else
      error ->
        error
    end
  end

  @doc """

  Same as `Puid.Entropy.bits_for_len/2` but either returns __bits__ or raises a
  `Puid.Error`

  ## Example

      iex> Puid.Entropy.bits_for_len!(:alphanum, 14)
      83

      iex> Puid.Entropy.bits_for_len!("dingosky", 14)
      42

  """
  @spec bits_for_len!(puid_chars(), non_neg_integer()) :: non_neg_integer()
  def bits_for_len!(chars, len) do
    with {:ok, ebpc} <- bits_for_len(chars, len) do
      ebpc
    else
      {:error, reason} ->
        raise(Puid.Error, reason)
    end
  end

  @doc """

  Length needed for a string generated from `chars` to have entropy `bits`.

  `chars` must be valid as per `Chars.charlist/1`.

  ## Example

      iex> Puid.Entropy.len_for_bits(:alphanum, 128)
      {:ok, 22}

      iex> Puid.Entropy.len_for_bits("dingosky", 128)
      {:ok, 43}

  """
  @spec len_for_bits(puid_chars(), non_neg_integer()) :: {:ok, non_neg_integer()} | Puid.Error.t()
  def len_for_bits(chars, bits) do
    with {:ok, ebpc} <- bits_per_char(chars) do
      {:ok, (bits / ebpc) |> :math.ceil() |> round()}
    else
      error ->
        error
    end
  end

  @doc """

  Same as `Puid.Entropy.len_for_bits/2` but either returns __len__ or raises a
  `Puid.Error`

  ## Example

      iex> Puid.Entropy.len_for_bits!(:alphanum, 128)
      22

      iex> Puid.Entropy.len_for_bits!('dingosky', 128)
      43

  """
  @spec len_for_bits!(puid_chars(), non_neg_integer()) :: non_neg_integer() | Puid.Error.t()
  def len_for_bits!(chars, bits) do
    with {:ok, len} <- len_for_bits(chars, bits) do
      len
    else
      {:error, reason} ->
        raise(Puid.Error, reason)
    end
  end
end
