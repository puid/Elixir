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

  ### :base16
  [RFC 4648](https://tools.ietf.org/html/rfc4648#section-8) base16 character set
  ```
  0123456789ABCDEF
  ```
  bits per character: `4`

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

  ### :base36
  Case-insensitive alphanumeric (lowercase)
  ```none
  0123456789abcdefghijklmnopqrstuvwxyz
  ```
  bits per character: `5.17`

  ### :base36_upper
  Case-insensitive alphanumeric (uppercase)
  ```none
  0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ
  ```
  bits per character: `5.17`

  ### :base45
  QR code alphanumeric mode (ISO/IEC 18004:2015)
  ```none
  0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:
  ```
  bits per character: `5.49`

  ### :base58
  Bitcoin Base58 alphabet (no 0, O, I, l)
  ```none
  123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
  ```
  bits per character: `5.86`

  ### :base62
  Alphanumeric characters (alias for :alphanum)
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
  ```
  bits per character: `5.95`

  ### :base85
  ASCII85/Ascii85 encoding (Adobe, btoa)
  ```none
  !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstu
  ```
  bits per character: `6.41`

  ### :bech32
  Bitcoin SegWit address encoding (no 1, b, i, o)
  ```none
  023456789acdefghjklmnpqrstuvwxyz
  ```
  bits per character: `5`

  ### :boolean
  Boolean/binary representation
  ```none
  TF
  ```
  bits per character: `1`

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

  ### :dna
  DNA nucleotide bases
  ```none
  ACGT
  ```
  bits per character: `2`

  ### :geohash
  Geohash encoding alphabet (base32 variant excluding 'a', 'i', 'l', 'o')
  ```none
  0123456789bcdefghjkmnpqrstuvwxyz
  ```
  bits per character: `5`

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
  Strings that don't look like English words and are easier to parse visually
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

  ### :url_safe
  RFC 3986 unreserved characters (URL safe without percent-encoding)
  ```none
  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~
  ```
  bits per character: `6.02`

  ### :word_safe32
  Strings that don't look like English words
  ```none
  23456789CFGHJMPQRVWXcfghjmpqrvwx
  ```
  Origin unknown

  bits per character: `5`

  ### :z_base32
  Zooko's human-oriented base32 (easier to read/transcribe)
  ```none
  ybndrfg8ejkmcpqxot1uwisza345h769
  ```
  bits per character: `5`

  """

  @typedoc """
  Chars can be designated by a pre-defined atom, a binary or a charlist
  """
  @type puid_chars() :: atom() | String.t() | charlist()

  @typedoc """
  Character encoding scheme. `:ascii` encoding uses cross-product character pairs.
  """
  @type puid_encoding() :: :ascii | :utf8

  @typedoc """
  Entropy sampler strategy used during ID generation.
  """
  @type sampler() :: :bit_shift | :interval

  @doc "List of predefined charsets discovered from compiled module."
  @spec predefined() :: [atom()]
  def predefined do
    beam = :code.which(__MODULE__)
    {:ok, {_, [{:abstract_code, {_, forms}}]}} = :beam_lib.chunks(beam, [:abstract_code])

    forms
    |> Enum.flat_map(fn
      {:function, _, :charlist!, 1, clauses} ->
        clauses
        |> Enum.flat_map(fn
          {:clause, _, [{:atom, _, name}], _, _} -> [name]
          _ -> []
        end)

      _ ->
        []
    end)
    |> Enum.uniq()
    |> Enum.filter(fn cs ->
      try do
        _ = charlist!(cs)
        true
      rescue
        _ -> false
      end
    end)
  end

  defp avg_bits_bit_shift(charset_size, bits_per_char, bit_shifts) do
    case Puid.Util.pow2?(charset_size) do
      true ->
        bits_per_char * 1.0

      false ->
        total_values = Puid.Util.pow2(bits_per_char)

        prob_accept = charset_size / total_values
        prob_reject = 1 - prob_accept

        reject_count = total_values - charset_size
        reject_bits = bits_consumed_on_reject(charset_size, total_values, bit_shifts)

        avg_bits_on_reject = reject_bits / reject_count
        bits_per_char + prob_reject / prob_accept * avg_bits_on_reject
    end
  end

  defp avg_bits_interval(charset_size, bits_per_char) do
    case Puid.Util.pow2?(charset_size) do
      true ->
        bits_per_char * 1.0

      false ->
        states = Enum.to_list(1..255)
        small_bits = interval_small_bits(charset_size)
        small_transitions = interval_small_transitions(charset_size)

        bits_by_state = interval_bits_by_state(charset_size, states, small_bits)

        transitions =
          states
          |> Enum.reduce(%{}, fn state, acc ->
            Map.put(
              acc,
              state,
              interval_transition_for_state(charset_size, state, small_transitions)
            )
          end)

        stationary = interval_stationary_distribution(states, transitions)

        stationary
        |> Enum.reduce(0.0, fn {state, prob}, sum ->
          sum + prob * Map.fetch!(bits_by_state, state)
        end)
    end
  end

  defp interval_bits_by_state(charset_size, states, small_bits) do
    states
    |> Enum.reduce(%{}, fn state, acc ->
      bits =
        cond do
          state < charset_size ->
            Map.fetch!(small_bits, state)

          true ->
            remainder = rem(state, charset_size)

            case remainder do
              0 -> 0.0
              _ -> remainder / state * Map.fetch!(small_bits, remainder)
            end
        end

      Map.put(acc, state, bits)
    end)
  end

  defp interval_small_bits(charset_size) do
    small_states = Enum.to_list(1..(charset_size - 1))

    initial =
      small_states
      |> Enum.reduce(%{}, fn state, acc ->
        Map.put(acc, state, 8.0)
      end)

    update = fn current ->
      small_states
      |> Enum.reduce(%{}, fn state, acc ->
        remainder = rem(256 * state, charset_size)
        reject_prob = remainder / (256 * state)
        tail_bits = Map.get(current, remainder, 0.0)
        Map.put(acc, state, 8.0 + reject_prob * tail_bits)
      end)
    end

    delta = fn current, next ->
      small_states
      |> Enum.reduce(0.0, fn state, max_delta ->
        abs(Map.fetch!(current, state) - Map.fetch!(next, state))
        |> max(max_delta)
      end)
    end

    iterate_until_converged(initial, update, delta, 1.0e-12, 10_000, "interval bits")
  end

  defp interval_small_transitions(charset_size) do
    small_states = Enum.to_list(1..(charset_size - 1))

    initial =
      small_states
      |> Enum.reduce(%{}, fn state, acc ->
        q = div(256 * state, charset_size)
        Map.put(acc, state, %{q => 1.0})
      end)

    update = fn current ->
      small_states
      |> Enum.reduce(%{}, fn state, acc ->
        m = 256 * state
        q = div(m, charset_size)
        remainder = rem(m, charset_size)
        reject_prob = remainder / m

        base = %{q => 1.0 - reject_prob}

        dist =
          case remainder do
            0 ->
              base

            _ ->
              base
              |> add_distribution(scale_distribution(Map.fetch!(current, remainder), reject_prob))
          end

        Map.put(acc, state, dist)
      end)
    end

    delta = fn current, next ->
      small_states
      |> Enum.reduce(0.0, fn state, max_delta ->
        distribution_delta(Map.fetch!(current, state), Map.fetch!(next, state))
        |> max(max_delta)
      end)
    end

    iterate_until_converged(
      initial,
      update,
      delta,
      1.0e-12,
      10_000,
      "interval transitions"
    )
  end

  defp interval_transition_for_state(charset_size, state, small_transitions) do
    cond do
      state < charset_size ->
        Map.fetch!(small_transitions, state)

      true ->
        q = div(state, charset_size)
        remainder = rem(state, charset_size)
        reject_prob = remainder / state

        case remainder do
          0 ->
            %{q => 1.0}

          _ ->
            %{q => 1.0 - reject_prob}
            |> add_distribution(
              scale_distribution(Map.fetch!(small_transitions, remainder), reject_prob)
            )
        end
    end
  end

  defp interval_stationary_distribution(states, transitions) do
    initial = %{1 => 1.0}

    update = fn current ->
      next =
        current
        |> Enum.reduce(%{}, fn {state, state_prob}, acc ->
          transitions
          |> Map.fetch!(state)
          |> Enum.reduce(acc, fn {next_state, transition_prob}, acc2 ->
            prob = state_prob * transition_prob
            Map.update(acc2, next_state, prob, &(&1 + prob))
          end)
        end)

      total_prob = next |> Map.values() |> Enum.sum()

      if total_prob == 0.0 do
        next
      else
        next
        |> Enum.reduce(%{}, fn {state, prob}, acc ->
          Map.put(acc, state, prob / total_prob)
        end)
      end
    end

    delta = fn current, next ->
      states
      |> Enum.reduce(0.0, fn state, max_delta ->
        abs(Map.get(current, state, 0.0) - Map.get(next, state, 0.0))
        |> max(max_delta)
      end)
    end

    iterate_until_converged(initial, update, delta, 1.0e-12, 25_000, "stationary distribution")
  end

  defp iterate_until_converged(_current, _update, _delta, _epsilon, 0, label) do
    raise(Puid.Error, "#{label} failed to converge")
  end

  defp iterate_until_converged(current, update, delta, epsilon, max_iter, label) do
    next = update.(current)

    case delta.(current, next) < epsilon do
      true ->
        next

      false ->
        iterate_until_converged(next, update, delta, epsilon, max_iter - 1, label)
    end
  end

  defp add_distribution(a, b) do
    b
    |> Enum.reduce(a, fn {state, prob}, acc ->
      Map.update(acc, state, prob, &(&1 + prob))
    end)
  end

  defp scale_distribution(distribution, factor) do
    distribution
    |> Enum.reduce(%{}, fn {state, prob}, acc ->
      Map.put(acc, state, prob * factor)
    end)
  end

  defp distribution_delta(a, b) do
    (Map.keys(a) ++ Map.keys(b))
    |> Enum.uniq()
    |> Enum.reduce(0.0, fn state, max_delta ->
      abs(Map.get(a, state, 0.0) - Map.get(b, state, 0.0))
      |> max(max_delta)
    end)
  end

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
      {:ok, ~c"2346789bdfghjmnpqrtBDFGHJLMNPQRT"}

      iex> Puid.Chars.charlist("dingosky")
      {:ok, ~c"dingosky"}

      iex> Puid.Chars.charlist("unique")
      {:error, "Characters not unique"}
  """
  @spec charlist(puid_chars()) :: {:ok, charlist()} | {:error, String.t()}
  def charlist(chars) do
    {:ok, charlist!(chars)}
  rescue
    error in Puid.Error ->
      {:error, error.message}
  end

  @doc """

  Same as `charlist/1` but either returns __charlist__ or raises a `Puid.Error`

  ## Example

      iex> Puid.Chars.charlist!(:safe32)
      ~c"2346789bdfghjmnpqrtBDFGHJLMNPQRT"

      iex> Puid.Chars.charlist!("dingosky")
      ~c"dingosky"

  Raises `Puid.Error` if the characters are not unique, too few, or contain invalid characters.
  """
  @spec charlist!(puid_chars()) :: charlist()
  def charlist!(chars)

  def charlist!(:alpha), do: charlist!(:alpha_upper) ++ charlist!(:alpha_lower)
  def charlist!(:alpha_lower), do: Enum.to_list(?a..?z)
  def charlist!(:alpha_upper), do: Enum.to_list(?A..?Z)
  def charlist!(:alphanum), do: charlist!(:alpha) ++ charlist!(:decimal)
  def charlist!(:alphanum_lower), do: charlist!(:alpha_lower) ++ charlist!(:decimal)
  def charlist!(:alphanum_upper), do: charlist!(:alpha_upper) ++ charlist!(:decimal)
  def charlist!(:base16), do: charlist!(:hex_upper)
  def charlist!(:base32), do: charlist!(:alpha_upper) ++ ~c"234567"
  def charlist!(:base32_hex), do: charlist!(:decimal) ++ Enum.to_list(?a..?v)
  def charlist!(:base32_hex_upper), do: charlist!(:decimal) ++ Enum.to_list(?A..?V)
  def charlist!(:base36), do: charlist!(:decimal) ++ charlist!(:alpha_lower)
  def charlist!(:base36_upper), do: charlist!(:decimal) ++ charlist!(:alpha_upper)
  def charlist!(:base45), do: ~c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
  def charlist!(:base58), do: ~c"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  def charlist!(:base62), do: charlist!(:alphanum)

  def charlist!(:base85),
    do:
      ~c"!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstu"

  def charlist!(:bech32), do: ~c"023456789acdefghjklmnpqrstuvwxyz"
  def charlist!(:boolean), do: ~c"TF"
  def charlist!(:crockford32), do: charlist!(:decimal) ++ (charlist!(:alpha_upper) -- ~c"ILOU")
  def charlist!(:decimal), do: Enum.to_list(?0..?9)
  def charlist!(:dna), do: ~c"ACGT"
  def charlist!(:geohash), do: ~c"0123456789bcdefghjkmnpqrstuvwxyz"
  def charlist!(:hex), do: charlist!(:decimal) ++ Enum.to_list(?a..?f)
  def charlist!(:hex_upper), do: charlist!(:decimal) ++ Enum.to_list(?A..?F)
  def charlist!(:safe_ascii), do: ?!..?~ |> Enum.filter(&safe_ascii?(&1))
  def charlist!(:safe32), do: ~c"2346789bdfghjmnpqrtBDFGHJLMNPQRT"

  def charlist!(:safe64),
    do: charlist!(:alpha_upper) ++ charlist!(:alpha_lower) ++ charlist!(:decimal) ++ ~c"-_"

  def charlist!(:symbol) do
    alphanum = charlist!(:alphanum)
    :safe_ascii |> charlist!() |> Enum.filter(&(!Enum.member?(alphanum, &1)))
  end

  def charlist!(:url_safe), do: charlist!(:alphanum) ++ ~c"-._~"
  def charlist!(:word_safe32), do: ~c"23456789CFGHJMPQRVWXcfghjmpqrvwx"
  # Backwards compatibility alias
  def charlist!(:wordSafe32), do: charlist!(:word_safe32)
  def charlist!(:z_base32), do: ~c"ybndrfg8ejkmcpqxot1uwisza345h769"

  def charlist!(charlist) when is_atom(charlist),
    do: raise(Puid.Error, "Invalid pre-defined charlist: :#{charlist}")

  def charlist!(chars) when is_binary(chars),
    do: chars |> to_charlist() |> validate_charlist()

  def charlist!(charlist) when is_list(charlist), do: validate_charlist(charlist)

  @doc false
  @spec encoding(charlist() | String.t()) :: puid_encoding()
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

  @doc """
  Calculate entropy metrics for a character set.

  ## Return Value

  Returns a map with the following keys:
  - `:avg_bits` - Average bits consumed per character
  - `:bit_shifts` - Bit shift rules used for character generation
  - `:ere` - Entropy representation efficiency (0 < ERE ≤ 1.0), measures how efficiently the characters represent entropy in their string form
  - `:ete` - Entropy transform efficiency (0 < ETE ≤ 1.0), measures how efficiently random bits are
    transformed into characters during generation

  ## Examples

      iex> Puid.Chars.metrics(:safe64)
      %{
        avg_bits: 6.0,
        bit_shifts: [{63, 6}],
        ere: 0.75,
        ete: 1.0
      }

      iex> Puid.Chars.metrics(:alpha)
      %{
        avg_bits: 6.769230769230769,
        bit_shifts: [{51, 6}, {55, 4}, {63, 3}],
        ere: 0.7125549647676365,
        ete: 0.8421104129072068
      }

  ## Details

  ERE: Entropy representation efficiency (0 < ERE ≤ 1.0), measures how efficiently ID characters
  represent entropy in their string form. For Puid this is always equivalent to the bits per
  character.

  ETE: Entropy transform efficiency (0 < ETE ≤ 1.0). Character sets with a power-of-2 number of
  characters have ETE = 1.0 since bit slicing always creates a proper index into the characters
  list. Other character sets discard some bits due to bit slicing that creates an out-of-bounds
  index. Puid uses an algorithm which minimizes the number of bits discarded.

  avg_bits: Theoretical average bits consumed per character

  :bit_shifts: Bit shift values used to determine how many bits are discarded during bit slicing.

  """
  @spec metrics(puid_chars()) :: %{
          avg_bits: float(),
          bit_shifts: [{non_neg_integer(), pos_integer()}, ...],
          ere: float(),
          ete: float()
        }
  def metrics(chars), do: metrics(chars, :bit_shift)

  @spec metrics(puid_chars(), sampler()) :: %{
          avg_bits: float(),
          bit_shifts: [{non_neg_integer(), pos_integer()}, ...],
          ere: float(),
          ete: float()
        }
  def metrics(chars, sampler) do
    charlist = charlist!(chars)
    charset_size = length(charlist)

    bit_shifts = Puid.Bits.bit_shifts(charset_size)
    bits_per_char = Puid.Util.log_ceil(charset_size)
    theoretical_bits = :math.log2(charset_size)

    # Calculate ERE (Entropy Representation Efficiency)
    avg_rep_bits_per_char =
      charlist
      |> to_string()
      |> byte_size()
      |> Kernel.*(8)
      |> Kernel./(charset_size)

    ere = theoretical_bits / avg_rep_bits_per_char

    avg_bits =
      case sampler do
        :bit_shift ->
          avg_bits_bit_shift(charset_size, bits_per_char, bit_shifts)

        :interval ->
          avg_bits_interval(charset_size, bits_per_char)

        _ ->
          raise(Puid.Error, "Invalid sampler. Must be :bit_shift or :interval")
      end

    ete = theoretical_bits / avg_bits

    %{
      avg_bits: avg_bits,
      bit_shifts: bit_shifts,
      ere: ere,
      ete: ete
    }
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

  # PRIVATE FUNCTIONS

  defp bits_consumed_on_reject(charset_size, total_values, bit_shifts) do
    charset_size..(total_values - 1)
    |> Enum.reduce(0, fn value, sum ->
      {_, bits_consumed} = find_bit_shift(value, bit_shifts)
      sum + bits_consumed
    end)
  end

  defp find_bit_shift(value, bit_shifts) do
    case Enum.find(bit_shifts, fn {max_val, _} -> value <= max_val end) do
      nil ->
        raise(
          Puid.Error,
          "bit_shifts #{inspect(bit_shifts)} has no matching bit shift rule for value #{value}"
        )

      result ->
        result
    end
  end

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
  defp safe_utf8?(g) when g < 0x00A1, do: false
  defp safe_utf8?(_), do: true

  defp unique?([], no_repeat?), do: no_repeat?

  defp unique?([char | charlist], seen) do
    if seen[char], do: unique?([], false), else: unique?(charlist, seen |> Map.put(char, true))
  end
end
