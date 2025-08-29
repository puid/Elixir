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

By default, `Puid` use the [RFC 4648](https://tools.ietf.org/html/rfc4648#section-5) file system & URL safe characters. The `chars` option can by used to specify any of 16 [pre-defined character sets](#Chars) or custom characters, including Unicode:

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

Generated IDs have at least 128-bit entropy by default. `Puid` provides a simple, intuitive way to specify ID randomness by declaring a `total` number of possible IDs with a specified `risk` of a repeat in that many IDs:

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

Note this is much more intuitive than guess, or simply not knowing, how much entropy your random IDs actually have.


### General Note

The mathematical approximations used by **Puid** always favor conservative estimatation:

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
  - may be larger than the specified `bits` since it is a multiple of the entropy bits per
    character
- entropy representation efficiency
  - ratio of the **puid** entropy to the bits required for **puid** string representation
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
  length: 22,
  rand_bytes: &:crypto.strong_rand_bytes/1
}
```

### Characters

There are 19 pre-defined character sets:

| Name              | Characters                                                                                    |
| :---------------- | :-------------------------------------------------------------------------------------------- |
| :alpha            | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz                                          |
| :alpha_lower      | abcdefghijklmnopqrstuvwxyz                                                                    |
| :alpha_upper      | ABCDEFGHIJKLMNOPQRSTUVWXYZ                                                                    |
| :alphanum         | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789                                |
| :alphanum_lower   | abcdefghijklmnopqrstuvwxyz0123456789                                                          |
| :alphanum_upper   | ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789                                                          |
| :base16           | 0123456789ABCDEF                                                                              |
| :base32           | ABCDEFGHIJKLMNOPQRSTUVWXYZ234567                                                              |
| :base32_hex       | 0123456789abcdefghijklmnopqrstuv                                                              |
| :base32_hex_upper | 0123456789ABCDEFGHIJKLMNOPQRSTUV                                                              |
| :crockford32      | 0123456789ABCDEFGHJKMNPQRSTVWXYZ                                                              |
| :decimal          | 0123456789                                                                                    |
| :hex              | 0123456789abcdef                                                                              |
| :hex_upper        | 0123456789ABCDEF                                                                              |
| :safe_ascii       | !#$%&()\*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^\_abcdefghijklmnopqrstuvwxyz{\|}~ |
| :safe32           | 2346789bdfghjmnpqrtBDFGHJLMNPQRT                                                              |
| :safe64           | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-\_                             |
| :symbol           | !#$%&()\*+,-./:;<=>?@[]^\_{\|}~                                                               |
| :wordSafe32       | 23456789CFGHJMPQRVWXcfghjmpqrvwx                                                              |

Any `String` of up to 256 unique characters can be used for **`puid`** generation, with custom characters optimized in the same manner as the pre-defined character sets. The characters must be unique. This isn't strictly a technical requirement, **PUID** could handle duplicate characters, but the resulting randomness of the IDs is maximal when the characters are unique, so **PUID** enforces that restriction.

#### Description of non-obvious character sets

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

Note: :safe32 and :wordSafe32 are two different strategies for the same goal.


## Comparisons

The Benchee benchmark script provides comparison of Puid to other libraries.

Quick

- Puid-only: mix run bench/compare.exs

Full comparisons (includes external libs via test-only deps)

- MIX_ENV=test mix run bench/compare.exs

Adjust workload

- TRIALS=100000 MIX_ENV=test mix run bench/compare.exs

Notes

- External libraries (EntropyString, Nanoid, Randomizer, SecureRandom, UUID) are included automatically when  MIX_ENV=test.
- Output shows ips and average times per scenario.

Example

```sh
MIX_ENV=test mix run bench/compare.exs

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
