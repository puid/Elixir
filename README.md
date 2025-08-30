# Puid

Simple, fast, flexible and efficient generation of probably unique identifiers (`puid`, aka random strings) of intuitively specified entropy using pre-defined or custom characters.

```elixir
iex> defmodule(RandId, do: use(Puid, chars: :alpha, total: 1.0e5, risk: 1.0e12))
iex> RandId.generate()
"YAwrpLRqXGlny"
```

[![Hex Version](https://img.shields.io/hexpm/v/puid.svg "Hex Version")](https://hex.pm/packages/puid) [![License: MIT](https://img.shields.io/npm/l/express.svg)]()

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
- [Installation](#installation)
- [Module API](#module-api)
- [Characters](#characters)
- [Metrics](#metrics)
- [Comparisons](#comparisons)

## Overview

**Puid** provides a means to create modules for generating random IDs. Specifically, **Puid** allows full control over all three key characteristics of generating random strings: entropy source, ID characters and ID randomness. 

A [general overview](https://github.com/puid/.github/blob/2381099d7f92bda47c35e8b5ae1085119f2a919c/profile/README.md) provides information relevant to the use of **Puid** for random IDs.


### Usage

`Puid` is used to create individual modules for random ID generation. Creating a random ID generator module is a simple as:

```elixir
iex> defmodule(SessionId, do: use(Puid))
iex> SessionId.generate()
"8nGA2UaIfaawX-Og61go5A"
```

The code above use default parameters, so `Puid` creates a module suitable for generating session IDs (ID entropy for the default module is 132 bits). Options allow easy and complete control of all three of the important facets of ID generation.

**Entropy Source**

`Puid` uses [:crypto.strong_rand_bytes/1](https://www.erlang.org/doc/man/crypto.html#strong_rand_bytes-1) as the default entropy source. The `rand_bytes` option can be used to specify any function of the form `(non_neg_integer) -> binary` as the source:

```elixir
iex > defmodule(PrngId, do: use(Puid, rand_bytes: &:rand.bytes/1))
iex> PrngId.generate()
"bIkrSeU6Yr8_1WHGvO0H3M"
```

**Characters**

By default, `Puid` use the [RFC 4648](https://tools.ietf.org/html/rfc4648#section-5) file system & URL safe characters. The `chars` option can by used to specify any of 19 [pre-defined character sets](#Chars) or custom characters, including Unicode:

```elixir
iex> defmodule(HexId, do: use(Puid, chars: :hex))
iex> HexId.generate()
"13fb81e35cb89e5daa5649802ad4bbbd"

iex> defmodule(DingoskyId, do: use(Puid, chars: "dingosky"))
iex> DingoskyId.generate()
"yiidgidnygkgydkodggysonydodndsnkgksgonisnko"

iex> defmodule(DingoskyUnicodeId, do: use(Puid, chars: "dîñgø$kyDÎÑGØßK¥", total: 2.5e6, risk: 1.0e15))
iex> DingoskyUnicodeId.generate()
"øßK$ggKñø$dyGîñdyØøØÎîk"

```

**Captured Entropy**

The default Puid module generates IDs that have 132-bit entropy. `Puid` provides a simple, intuitive way to specify ID randomness by declaring a `total` number of possible IDs with a specified `risk` of a repeat in that many IDs:

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

### General Note

The mathematical approximations used by **Puid** always favor conservative estimation:

- overestimate the **bits** needed for a specified **total** and **risk**
- overestimate the **risk** of generating a **total** number of **puid**s
- underestimate the **total** number of **puid**s that can be generated at a specified **risk**

### Installation

Add `puid` to `mix.exs` dependencies:

```elixir
def deps,
  do: [
    {:puid, "~> 2.1"}
  ]
```

Update dependencies

```bash
mix deps.get
```

### Module API

`Puid` modules have the following functions:

- **generate/0**: Generate a random **puid**
- **total/1**: total **puid**s which can be generated at a specified `risk`
- **risk/1**: risk of generating `total` **puid**s
- **encode/1**: Encode `bytes` into a **puid**
- **decode/1**: Decode a `puid` into **bytes**
- **info/0**: Module information

The `total/1`, `risk/1` functions provide approximations to the **risk** of a repeat in some **total** number of generated **puid**s. The mathematical approximations used purposely _overestimate_ **risk** and _underestimate_ **total**.

The `encode/1`, `decode/1` functions convert `String.t()` **puid**s to and from `bitstring` **bits** to facilitate binary data storage, e.g. as an **Ecto** type.

The `info/0` function returns a `Puid.Info` structure consisting of:

- source characters
- name of pre-defined `Puid.Chars` or `:custom`
- entropy bits per character
- total entropy bits
    - may be larger than the specified `bits` since it is a multiple of the entropy bits per character
- entropy representation efficiency
    - ratio of **puid** entropy to bits required for **puid** string representation
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

iex> SafeId.encode(<<9, 37, 132, 60, 189, 192, 137, 235, 97, 117, 129, 101, 9, 180, 154, 84, 2::size(4)>>)
"CSWEPL3AiethdYFlCbSaVC"

iex> SafeId.info()
%Puid.Info{
  characters: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
  char_set: :safe64,
  entropy_bits: 132.0,
  entropy_bits_per_char: 6.0,
  ere: 0.75,
  ete: 1.0,
  length: 22,
  rand_bytes: &:crypto.strong_rand_bytes/1
}
```

### Characters

#### Puid Predefined Charsets

| Name | Length | ERE | ETE | Characters |
|------|--------|-----|-----|------------|
| :alpha | 52 | 5.7 | 0.84 | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz |
| :alpha_lower | 26 | 4.7 | 0.81 | abcdefghijklmnopqrstuvwxyz |
| :alpha_upper | 26 | 4.7 | 0.81 | ABCDEFGHIJKLMNOPQRSTUVWXYZ |
| :alphanum | 62 | 5.95 | 0.97 | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 |
| :alphanum_lower | 36 | 5.17 | 0.65 | abcdefghijklmnopqrstuvwxyz0123456789 |
| :alphanum_upper | 36 | 5.17 | 0.65 | ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 |
| :base16 | 16 | 4.0 | 1.0 | 0123456789ABCDEF |
| :base32 | 32 | 5.0 | 1.0 | ABCDEFGHIJKLMNOPQRSTUVWXYZ234567 |
| :base32_hex | 32 | 5.0 | 1.0 | 0123456789abcdefghijklmnopqrstuv |
| :base32_hex_upper | 32 | 5.0 | 1.0 | 0123456789ABCDEFGHIJKLMNOPQRSTUV |
| :crockford32 | 32 | 5.0 | 1.0 | 0123456789ABCDEFGHJKMNPQRSTVWXYZ |
| :decimal | 10 | 3.32 | 0.62 | 0123456789 |
| :hex | 16 | 4.0 | 1.0 | 0123456789abcdef |
| :hex_upper | 16 | 4.0 | 1.0 | 0123456789ABCDEF |
| :safe_ascii | 90 | 6.49 | 0.8 | !#$%&()\*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ\[]^\_abcdefghijklmnopqrstuvwxyz{\|}~ |
| :safe32 | 32 | 5.0 | 1.0 | 2346789bdfghjmnpqrtBDFGHJLMNPQRT |
| :safe64 | 64 | 6.0 | 1.0 | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-\_ |
| :symbol | 28 | 4.81 | 0.89 | !#$%&()\*+,-./:;<=>?@\[]^\_{\|}~ |
| :wordSafe32 | 32 | 5.0 | 1.0 | 23456789CFGHJMPQRVWXcfghjmpqrvwx |

Note: The [Metrics](#metrics) section explains ERE and ETE.

##### Description of non-obvious character sets

| Name              | Description                                                |
| :---------------- | :--------------------------------------------------------- |
| :base16           | https://datatracker.ietf.org/doc/html/rfc4648#section-8    |
| :base32           | https://datatracker.ietf.org/doc/html/rfc4648#section-6    |
| :base32_hex       | Lowercase of :base32_hex_upper                             |
| :base32_hex_upper | https://datatracker.ietf.org/doc/html/rfc4648#section-7    |
| :crockford32      | https://www.crockford.com/base32.html                      |
| :safe_ascii       | Printable ascii that does not require escape in String     |
| :safe32           | Alpha and numbers picked to reduce chance of English words |
| :safe64           | https://datatracker.ietf.org/doc/html/rfc4648#section-5    |
| :wordSafe32       | Alpha and numbers picked to reduce chance of English words |

Note: `:safe32` and `:wordSafe32` are two different strategies for the same goal.

#### Custom

Any `String` of up to 256 unique characters can be used for **`puid`** generation, with custom characters optimized in the same manner as the pre-defined character sets. The characters must be unique. This isn't strictly a technical requirement, **PUID** could handle duplicate characters, but the resulting randomness of the IDs is maximal when the characters are unique, so **PUID** enforces that restriction.

### Metrics

#### Entropy Representation Efficiency

Entropy Representation Efficiency (ERE) is a measure of how efficient a string ID represents the entropy of the ID itself. When referring to the entropy of an ID, we mean the Shannon Entropy of the character sequence, and that is maximal when all the permissible characters are equally likely to occur. In most random ID generators, this is the case, and the ERE is solely dependent on the count of characters in the charset, where each character represents **log2(count)** of entropy (a computer specific calc of general Shannon entropy). For example, for a hex charset there are **16** hex characters, so each character "carries" **log2(16) = 4** bits of entropy in the string ID. We say the bits per character is **4** and a random ID of **12** hex characters has **48** bits of entropy.

ERE is measured as a ratio of the bits of entropy for the ID divided by the number of bits require to represent the string (**8** bits per ID character). If each character is equally probably (the most common case), ERE is **(bits-per-char * id_len) / (8 bits * id_len)**, which simplifies to **bits-per-character/8**. The BPC displayed in the Puid Characters table is equivalent to the ERE for that charset.

There is, however, a particular random ID exception where each character is _**not**_ equally probable, namely, the often used v4 format of UUIDs. In that format, there are hyphens that carry no entropy (entropy is uncertainty, and there is _**no uncertainly**_ as to where those hyphens will be), one hex digit that is actually constrained to 1 of only 4 hex values and another that is fixed. This formatting results in a ID of 36 characters with a total entropy of 122 bits. The ERE of a v4 UUID is, therefore, **122 / (8 * 36) = 0.4236**.

#### Entropy Transform Efficiency

Entropy Transform Efficiency (ETE) is a measure of how efficiently source entropy is transformed into random ID entropy. For charsets with a character count that is a power of 2, all of the source entropy bits can be utilized during random ID generation. Each generated ID character requires exactly **log2(count)** bits, so the incoming source entropy can easily be carved into appropriate indices for character selection. Since ETE represents the ratio of output entropy bits to input entropy source, when all of the bits are utilized ETE is **1.0**.

Even for charsets with power of 2 character count, ETE is only the theoretical maximum of **1.0** _**if**_ the input entropy source is used as described above. Unfortunately, that is not the case with many random ID generation schemes. Some schemes use the entire output of a call to source entropy to create a single index used to select a character. Such schemes have very poor ETE.

For charsets with a character count that is not a power of 2, some bits will inevitably be discarded since the smallest number of bits required to select a character, **ceil(log2(count))**, will potentially result in an index beyond the character count. A first-cut, naïve approach to this reality is to simply throw away all the bits when the index is too large.

However, a more sophisticated scheme of bit slicing can actually improve on the naïve approach. Puid extends the bit slicing scheme by adding a bit shifting scheme to the algorithm, wherein a _**minimum**_ number of bits in the "over the limit" bits are discarded by observing that some bit patterns of length less than **ceil(log2(count))** already guarantee the bits will be over the limit, and _**only**_ those bits need be discarded. 

As example, using the **:alphanum_lower** charset, which has 36 characters, **ceil(log2(36)) = 6** bits are required to create a suitable index. However, if those bits start with the bit pattern **11xxxx**, the index would be out of bounds regardless of the **xxxx** bits, so Puid only tosses the first two bits and keeps the trailing four bits for use in the next index. (It is beyond scope to discuss here, but analysis shows this bit shifting scheme does not alter the random characteristics of generated IDs). So whereas the naïve approach would have an ETE of **0.485**, Puid achieves an ETE of **0.646**, a **33%** improvement. The `bench/alphanum_lower_ete.exs` script has detailed analysis.

## Comparisons

### Speed

`bench/compare_libs.exs` provides some comparison of Puid and other random ID libraries.

Notes

- run: `MIX_ENV=test mix run bench/compare_libs.exs`
    - `MIX_ENV=test` is required to include external libraries
- override trials via env var: `TRIALS=100000 MIX_ENV=test mix run bench/compare_libs.exs`
- ips and average times per scenario
- speed comparison wrt Puid using hex and CSPRNG

Example

```sh
MIX_ENV=test mix run bench/compare_libs.exs

Name                                  ips        average  deviation         median         99th %
Puid hex (CSPRNG)                   47.74       20.95 ms     ±1.13%       20.90 ms       21.59 ms
SecureRandom urlsafe_base64         40.63       24.61 ms     ±2.90%       24.28 ms       27.22 ms
Puid safe64 (PRNG)                  32.80       30.48 ms     ±5.00%       30.47 ms       33.02 ms
Puid safe64 (CSPRNG)                29.75       33.61 ms     ±3.30%       33.21 ms       38.22 ms
UUID v4 (string)                    27.39       36.51 ms     ±6.40%       35.26 ms       41.94 ms
Puid alphanum (CSPRNG)              12.68       78.85 ms     ±1.44%       78.72 ms       82.99 ms
EntropyString safe64                 5.69      175.63 ms     ±0.77%      175.78 ms      178.20 ms
Randomizer alphanum 22               4.63      216.09 ms    ±14.59%      206.54 ms      304.81 ms
Common Solution alphanum             1.25      797.20 ms     ±1.14%      796.77 ms      806.53 ms
Nanoid (CSPRNG)                      0.79     1266.43 ms     ±0.99%     1266.43 ms     1275.32 ms

Comparison:
Puid hex (CSPRNG)                   47.74
SecureRandom urlsafe_base64         40.63 - 1.17x slower +3.66 ms
Puid safe64 (PRNG)                  32.80 - 1.46x slower +9.54 ms
Puid safe64 (CSPRNG)                29.75 - 1.60x slower +12.66 ms
UUID v4 (string)                    27.39 - 1.74x slower +15.57 ms
Puid alphanum (CSPRNG)              12.68 - 3.76x slower +57.90 ms
EntropyString safe64                 5.69 - 8.38x slower +154.68 ms
Randomizer alphanum 22               4.63 - 10.31x slower +195.14 ms
Common Solution alphanum             1.25 - 38.05x slower +776.25 ms
Nanoid (CSPRNG)                      0.79 - 60.45x slower +1245.48 ms
```

### Puid charsets ID length and ERE

The `bench/puid_ere_len.exs` script outputs a markdown table comparing the number of actual entropy bits and resulting `puid` lengths for each `Puid` predefined charset. The default target bits are `64, 86, 128, 256`.

    mix run bench/puid_ere_len.exs [bits...]

| charset | ere |  | bits | len |  | bits | len |  | bits | len |  | bits | len |
| --- | ---: | --- | ---: | ---: | --- | ---: | ---: | --- | ---: | ---: | --- | ---: | ---: |
|  |  |  | 64 | — |  | 96 | — |  | 128 | — |  | 256 | — |
| alpha | 0.71 |  | 68.41 | 12 |  | 96.91 | 17 |  | 131.11 | 23 |  | 256.52 | 45 |
| alpha_lower | 0.59 |  | 65.81 | 14 |  | 98.71 | 21 |  | 131.61 | 28 |  | 258.52 | 55 |
| alpha_upper | 0.59 |  | 65.81 | 14 |  | 98.71 | 21 |  | 131.61 | 28 |  | 258.52 | 55 |
| alphanum | 0.74 |  | 65.5 | 11 |  | 101.22 | 17 |  | 130.99 | 22 |  | 256.03 | 43 |
| alphanum_lower | 0.65 |  | 67.21 | 13 |  | 98.23 | 19 |  | 129.25 | 25 |  | 258.5 | 50 |
| alphanum_upper | 0.65 |  | 67.21 | 13 |  | 98.23 | 19 |  | 129.25 | 25 |  | 258.5 | 50 |
| base16 | 0.5 |  | 64.0 | 16 |  | 96.0 | 24 |  | 128.0 | 32 |  | 256.0 | 64 |
| base32 | 0.63 |  | 65.0 | 13 |  | 100.0 | 20 |  | 130.0 | 26 |  | 260.0 | 52 |
| base32_hex | 0.63 |  | 65.0 | 13 |  | 100.0 | 20 |  | 130.0 | 26 |  | 260.0 | 52 |
| base32_hex_upper | 0.63 |  | 65.0 | 13 |  | 100.0 | 20 |  | 130.0 | 26 |  | 260.0 | 52 |
| crockford32 | 0.63 |  | 65.0 | 13 |  | 100.0 | 20 |  | 130.0 | 26 |  | 260.0 | 52 |
| decimal | 0.42 |  | 66.44 | 20 |  | 96.34 | 29 |  | 129.56 | 39 |  | 259.11 | 78 |
| hex | 0.5 |  | 64.0 | 16 |  | 96.0 | 24 |  | 128.0 | 32 |  | 256.0 | 64 |
| hex_upper | 0.5 |  | 64.0 | 16 |  | 96.0 | 24 |  | 128.0 | 32 |  | 256.0 | 64 |
| safe_ascii | 0.81 |  | 64.92 | 10 |  | 97.38 | 15 |  | 129.84 | 20 |  | 259.67 | 40 |
| safe32 | 0.63 |  | 65.0 | 13 |  | 100.0 | 20 |  | 130.0 | 26 |  | 260.0 | 52 |
| safe64 | 0.75 |  | 66.0 | 11 |  | 96.0 | 16 |  | 132.0 | 22 |  | 258.0 | 43 |
| symbol | 0.6 |  | 67.3 | 14 |  | 96.15 | 20 |  | 129.8 | 27 |  | 259.6 | 54 |
| wordSafe32 | 0.63 |  | 65.0 | 13 |  | 100.0 | 20 |  | 130.0 | 26 |  | 260.0 | 52 |

| Library | Charset | Target | Lib Len | Lib Bits | Lib ERE | Puid Len | Puid Bits | Puid ERE | ERE Δ% |
|---------|---------|--------|---------|----------|---------|----------|-----------|----------|--------|
| Nanoid | safe64 | 126 | 21 | 126.0 | 0.75 | 21 | 126.0 | 0.75 | 0.0% |
| Randomizer | alphanum_lower | 52 | 10 | 51.7 | 0.65 | 11 | 56.87 | 0.65 | 0.0% |
| SecureRandom.urlsafe_base64 | safe64 | 128 | 22 | 132.0 | 0.75 | 22 | 132.0 | 0.75 | 0.0% |
| UUID v4 | hex | 122 | 32 | 128.0 | 0.5 | 31 | 124.0 | 0.5 | 0.0% |

ERE = Entropy Representation Efficiency (higher is better)