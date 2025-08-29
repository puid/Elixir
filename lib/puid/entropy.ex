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

  @doc """
  Entropy bits necessary to generate `total` number of `puid`s with `risk` risk of repeat.

  The total number of possible `puid`s is 2<sup>bits</sup>.
  Risk is expressed as a 1 in `risk` chance, so the probability of a repeat is `1/risk`.

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
    n = 2 * :math.log2(total)
    n + :math.log2(risk) - 1
  end

  @doc """
  Approximate total number of `puid`s which can be generated using `bits` bits entropy at a `risk` risk of repeat.

  The total number of possible `puid`s is 2<sup>bits</sup>.
  Risk is expressed as a 1 in `risk` chance, so the probability of a repeat is `1/risk`.

  This approximation is conservative and will understate the true total.

  ## Example

      iex> bits = 64
      iex> risk = 1.0e9
      iex> Puid.Entropy.total(bits, risk)
      192077

  """
  @spec total(bits :: float(), risk :: float()) :: integer()
  def total(0, _), do: 0
  def total(1, _), do: 1

  def total(_, 0), do: 1
  def total(_, 1), do: 1

  def total(bits, risk) do
    c = 2 ** (bits + 1) / risk
    round(:math.sqrt(c))
  end

  @doc """
  Risk of repeat in `total` number of events with `bits` bits entropy.

  The total number of possible `puid`s is 2<sup>bits</sup>.
  Risk is expressed as a 1 in `risk` chance, so the probability of a repeat is `1/risk`.

  This approximation is conservative and will understate the true risk.

  ## Example

      iex> bits = 96
      iex> total = 1.0e7
      iex> Puid.Entropy.risk(bits, total)
      1584563250285288
      iex> 1.0 / 1584563250285288
      6.31088724176809e-16
  """
  @spec risk(bits :: float(), total :: float()) :: integer()
  def risk(0, _), do: 0
  def risk(1, _), do: 1

  def risk(_, 0), do: 1
  def risk(_, 1), do: 1

  def risk(bits, total) do
    n = 2 * :math.log2(total)
    round(2 ** (bits - n + 1))
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
  @spec bits_per_char(Puid.Chars.puid_chars()) :: {:ok, float()} | {:error, String.t()}
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
  @spec bits_per_char!(Puid.Chars.puid_chars()) :: float()
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

      iex> Puid.Entropy.bits_for_len(~c'dingosky', 14)
      {:ok, 42}

  """
  @spec bits_for_len(Puid.Chars.puid_chars(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
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
  @spec bits_for_len!(Puid.Chars.puid_chars(), non_neg_integer()) :: non_neg_integer()
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
  @spec len_for_bits(Puid.Chars.puid_chars(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
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

      iex> Puid.Entropy.len_for_bits!(~c'dingosky', 128)
      43

  """
  @spec len_for_bits!(Puid.Chars.puid_chars(), non_neg_integer()) ::
          non_neg_integer()
  def len_for_bits!(chars, bits) do
    with {:ok, len} <- len_for_bits(chars, bits) do
      len
    else
      {:error, reason} ->
        raise(Puid.Error, reason)
    end
  end
end
