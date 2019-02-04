# Puid

Efficiently generate cryptographically strong probably unique identifier (**puid**, aka random string) of specified entropy from various character sets.

[![Build Status](https://travis-ci.org/puid/Elixir.svg?branch=master)](https://travis-ci.org/puid/Elixir) &nbsp; [![Hex Version](https://img.shields.io/hexpm/v/puid.svg "Hex Version")](https://hex.pm/packages/puid) &nbsp; [![License: MIT](https://img.shields.io/npm/l/express.svg)]()

## <a name="TOC"></a>TOC
 - [Installation](#Installation)
 - [Usage](#Usage)
 - [Overview](#Overview)
 - [Why puid?](#WhyPuid)
 - [Why Not uuid?](#WhyNotUuid)
 - [Features](#Features)
 - [Library Comparisons](#Comparisons)
    - [Common Solution](#Common_Solution)
    - [EntropyString](#EntropyString)
    - [gen_reference](#gen_reference)
    - [Misc.Random](#Misc_Random)
    - [Not_Qwerty123](#Not_Qwerty123)
    - [Randomizer](#Randomizer)
    - [rand_str](#rand_str)
    - [SecureRandom](#SecureRandom)
    - [UUID](#uuid)

## <a name="Installation"></a>Installation

Add `puid` to `mix.exs` dependencies:

  ```elixir
  def deps,
    do: [ 
      {:puid, "~> 1.0"}
    ]
  ```

Update dependencies

  ```bash
  mix deps.get
  ```

[TOC](#TOC)

## <a name="Usage"></a>Usage

Create a module for generating **puid**s:

```elixir
  iex> defmodule(MyPuid, do: use(Puid))
  iex> MyPuid.generate()
  "8nGA2UaIfaawX-Og61go5A"
```

By default, `Puid` modules generate **puid**s with 128-bit of entropy using the [RFC 4648](https://tools.ietf.org/html/rfc4648#section-5) file system and URL safe characters. There are 16 pre-defined character sets specified in `Puid.CharSet`.

To **puid**s with 92-bits of entropy from alphanumeric characters:

```elixir
  iex> defmodule(AlphanumPuid, do: use(Puid, bits: 92, charset: :alphanum))
  iex> AlphanumPuid.generate()
  "4ParCeRyqN8jgWh0"
```

Or to use custom characters for 64-bit entropy **puid**s:

```elixir
  iex> defmodule(DingoskyPuid, do: use(Puid, bits: 64, chars: "dingosky"))
  iex> DingoskyPuid.generate()
  "dskyyssgiydygkgndoykgs"
```

You can even use Unicode characters:

```elixir
  iex> defmodule(UnicodePuid, do: use(Puid, chars: "ŮήιƈŏδεĊħąŕαсτəř"))
  iex> UnicodePuid.generate()
  "ĊŮəαсŕąδřτąƈιřήсąιŕŮτąąƈτŏřŏτсřŏ"
```

Rather than explicitly setting the `bits` parameter, `Puid` provides a simple, intuitive way to specify the amount of entropy for generated `puid`s.  By specifying a `total` number of IDs with a `risk` of a repeat, `Puid` will calculate the required entropy bits.

Generate up to _10 million_ **puid**s with _1 in a trillion_ chance of repeat:

```elixir
  iex> defmodule(SafePuid, do: use(Puid, total: 10.0e6, risk: 1.0e12))
  iex> SafePuid.generate()
  "q4SbN9yEXEiVCyc"
```

Each defined module has an `info/0` function that provides detail on the module specification:

```elixir
  iex> SafePuid.info()
  %Puid.Info{
    chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
    charset: :safe64,
    entropy_bits: 90.0,
    entropy_bits_per_char: 6.0,
    ere: 0.75,
    rand_bytes: &:crypto.strong_rand_bytes/1,
    length: 15
  }
```

[TOC](#TOC)

### <a name="Overview"></a>Overview

We frequently have a need for unique identifiers. Regardless of how we generate these identifiers, we should question if they are, well, _unique_. Guaranteeing uniqueness requires either deterministic generation (e.g., a counter) that is not random, or that each newly created random identifier be compared against all existing IDs. However, often neither deterministic IDs nor the overhead of comparing all generated IDs suites our need.

So we use random IDs (aka random strings), which means we drop _guaranteed uniqueness_ and adopt a weaker strategy of _probabilistic uniqueness_. Specifically, rather than being absolutely sure of uniqueness, we settle for a statement such as *"there is less than a 1 in a billion chance that two of my strings are the same"*. We use an implicit version of this very strategy every time we use a hash as a key. We *assume* there will be no hash collision, but we **_do not_** have any true _guarantee of uniqueness_ per se.

Understanding _probabilistic uniqueness_ requires an understanding of [*entropy*](https://en.wikipedia.org/wiki/Entropy_(information_theory)) and of how to estimate the probability of a [*collision*](https://en.wikipedia.org/wiki/Birthday_problem#Cast_as_a_collision_problem) (i.e., the probability that two strings in a set of randomly generated strings might be the same). The blog post [Hash Collision Probabilities](http://preshing.com/20110504/hash-collision-probabilities/) provides an excellent overview of deriving an expression for calculating the probability of a collision in some number of instances of a perfect N-bit hash. Although the blog post provides detail for calculating the probability of a hash collision, it does not provide an answer to quantifying what we mean by _"there is less than a 1 in a billion chance that 1 million strings of this form will have a repeat"_. That requires we calculate the entropy necessary to generate a **_total_** number of strings (from a much larger pool of possible strings) with a given **_risk_** of a repeat.

`Puid` provides easy creation of modules for randomly generating _probably unique identifiers_ (**puid**s) from a given character set such that a **_total_** number of the strings can be generated with a specified **_risk_** of repeat.


[TOC](#TOC)

## <a name="WhyPuid"></a>Why Puid?

As developers, we aren't accustom to thinking of random strings as being _probably unique_, but that's exactly what they are. But more importantly, we often don't consider what the actual probability of that uniqueness is. As example, consider any of the libraries (other than `Puid` and [EntropyString](https://hex.pm/packages/entropy_string), a precursor to `Puid`) or common schemes for generating random strings. They all accept as specification the **_length_** of the string, and perhaps the characters to use. However, they do not address the critical question: _How likely am I to create a repeat if I use this library for N number of strings?_

That question really should drive the parameterization of random string generation. You don't need a string of length 12; you need 100,000 identifiers using some character set with a explicit probability of a repeat. Let the library determine how long the string will be. 

[TOC](#TOC)

## <a name="WhyNotUuid"></a>Why Not uuid?

Given the issue raised in [Why Puid?](#WhyPuid), developers often punt and simply adopt a strategy of using **uuid**s instead. The leading reason for using **uuid**s seems to be "I want unique IDs" (with an implicit "and I don't want to think about it any further"). But **uuid**s (the version 4 string representation defined in [Section 4.4 of RFC 4122](https://tools.ietf.org/html/rfc4122#section-4.4)) are neither universal nor unique.

Far too often the rational of using **uuid**s is that the probability of a repeat is low. (This is actually an underspecified statement; calculating the probability requires specifying the total number of **uuid**s generated). But if that rationale holds, why not concatenate two **uuid**s and even be "safer". And we sink into [7 Minute Abs](https://www.youtube.com/watch?v=JB2di69FmhE) logic.

Better to explicitly declare your intentions. Suppose you're generating 1 million IDs (for whatever reason). If you use **uuid**s, what is the risk of repeat? Be quick now. OK, don't be quick. The risk is about 1 in 10^25. That's 1 in 10 septillion, or perhaps we should call it 1 in a 7 Minute Ab.

Suppose instead you accept a risk of repeat as being about the same as that of you being hit by a meteorite as you are writing code. We'll [estimate](https://www.theguardian.com/commentisfree/2011/oct/13/meteorite-space-earth) that event as 1 in 2.0e13. Using `Puid`, we can generate 1 million of these IDs at that risk using:

```elixir
  iex> defmodule(MeteorId, do: use(Puid, total: 1.0e6, risk: 2.0e13))
  iex> MeteorId.generate()
  "EN8jD6p0NucjpA"
```

The `Puid` specification is explicit. The code clearly shows the expected number of IDs to generate under the given risk of a repeat. No guesswork needed.

##### [But wait, there's more!](https://en.wikipedia.org/wiki/Ron_Popeil)

A **uuid** has 122-bits of entropy (although most libraries use 128 bits to actually generate the **uuid**). The [string representation](https://tools.ietf.org/html/rfc4122#section-4.4) requires 36 characters. Let's look at that string length. Using the **MeteorId** module, your random **puid**s are 14 characters each. Using the overkill of **uuid**s, each random ID is 36 characters. One solution requires 14 characters per ID. The other 36. Enough said.

Well, maybe not. Suppose you _really, really_ want that overkill. OK, let's overkill with `Puid`:

```elixir
  iex> defmodule(OverkillPuid, do: use(Puid, bits: 122))
  iex> OverkillPuid.generate()
  "geDpoXs5KMDgPKbDD5ch"
```

The `OverkillPuid` pool of random strings is slightly larger size than **uuid**s. So the risk of repeat in some number of instances is similar. And yet, each `OverkillPuid` **puid** only requires 21 characters, whereas each equivalent **uuid** is 36 characters. Basically, a **uuid** _is_ a **puid** with a fixed entropy of 122 bits and a comparatively inefficient string representation. Overkill if you must, but even then `Puid` is more efficient that using **uuid**s.


[TOC](#TOC)

## <a name="Features"></a>Features

### <a name="CharSets"></a>CharSets

  - Predefined
    - 16 pre-defined character sets
    - Optimized ID generation for each of the pre-defined characters sets 
  - Custom
    - Any string of unique characters can be used for **puid**s, including Unicode characters.
### <a name="RandomBytes"></a>Random Bytes

By default, `Puid` uses `:crypto.strong_rand_bytes/1` for entropy. Any function of the form `(non_neg_integer) -> binary` can be used instead.

### <a name="PuidInfo"></a>**puid** `info`

Each `Puid` generated module creates an `info/0` function which provides information regarding the parameterization of the **puid** module. This information includes:

  - **puid** string length
  - The source character set
  - The pre-defined `Puid.CharSet` used, or if characters are custom
  - **puid** entropy bits per character
  - **puid** total entropy bits
    - May be larger than the specified `bits` since the total is a product of the **puid** length and the entropy bits per character.
  - **puid** entropy representation efficiency.
    - The ratio of the **puid** total entropy to the bits required for the **puid** string representation.
  - Source function for entropy

[TOC](#TOC)

## <a name="Comparisons"></a>Library Comparisons

The following provides comparisons to existing Elixir methods of generating random IDs. In each case, an equivalent `Puid` module is created. The **Timing** section includes a rough execution time comparison. Where appropriate, the existing Elixir method is run under pseudo-random number generation (PRNG) as well as cryptographically strong pseudo-random number generation (CSPRNG), the latter being slower. All comparisons use the default `Puid` CSPRNG entropy source.

The source for the **Timing** output is in the `test/timing.exs` file. Module tags provide an easy means of running the timing test for a particular existing solution. For example, to run the timing test for [Misc.Random](https://hex.pm/packages/misc_random):

```elixir
  > mix test test/timing.exs --only misc_random
```

### <a name="Common_Solution"></a>Common Solution

The common solution to generating random strings in just about every computer language boils down to the same strategy: from a source character set, create a string where each character is plucked from the source by randomly indexing into the set. In Elixir, this looks like:

```elixir
defmodule CommonSolution do
  def rand_string(len, chars) do
    char_count = chars |> String.length()

    for(_ <- 1..len, do: :rand.uniform(char_count) - 1)
    |> Enum.map(&(chars |> String.at(&1)))
    |> List.to_string()
  end
end
```

#### Specification 

  - specify string length and character set
  - no pre-defined character sets 
  - supports custom characters
    - handles Unicode strings

#### Examples

```elixir
  iex> len = 12
  iex> chars = ?a..?z |> Enum.to_list() |> to_string()
  "abcdefghijklmnopqrstuvwxyz"
  iex> CommonSolution.rand_string(len, chars)
  "ckukdbpynhev"
  
  iex> bits = Puid.Entropy.bits_for_string!(len, :alpha_lower)
  iex> defmodule(AlphaLowerPuid, do: use(Puid, bits: bits, charset: :alpha_lower))
  iex> AlphaLowerPuid.generate()
  "atszyoutahxm"

  iex> CommonSolution.rand_string(len, "ŮήιƈŏδεĊħąŕαсτəř")
  "ετδąřŕτŏŮŕəŮ"
  
  iex> bits = Puid.Entropy.bits_for_string!(len, "ŮήιƈŏδεĊħąŕαсτəř")
  iex> defmodule(UnicodePuid, do: use(Puid, bits: bits, chars: "ŮήιƈŏδεĊħąŕαсτəř"))
  iex> UnicodePuid.generate()
  "ααιĊδħąιссήą"
```

#### Timing

```
Generate 50000 random IDs with 128 bits of entropy using alphanum characters
  Common Solution   (PRNG) : 5.796959
  Common Solution (CSPRNG) : 7.824981
  Puid            (CSPRNG) : 0.528811

Generate 50000 random IDs with 128 bits of entropy using 8 custom characters
  Common Solution   (PRNG) : 1.365407
  Common Solution (CSPRNG) : 4.430985
  Puid            (CSPRNG) : 0.720929

Generate 50000 random IDs with 92 bits of entropy using 16 unicode characters
  Common Solution   (PRNG) : 2.437136
  Common Solution (CSPRNG) : 4.922621
  Puid            (CSPRNG) : 2.760375
```      

### <a name="entropy_string"></a>[EntropyString](https://hex.pm/packages/entropy_string)

#### Specification 

  - specify string entropy
  - 6 pre-defined character sets 
  - supports custom characters
     - character set count is restricted to powers of 2
     - does not handle Unicode

#### Examples

```elixir
  iex> defmodule(IdES128, do: use(EntropyString, charset: :charset64))
  iex> IdES128.random()
  "RfYP7I5fitDij2Ow4eYgnd"
  
  iex> defmodule(Safe64Puid128, do: use(Puid, charset: :safe64))
  iex> Safe64Puid128.generate()
  "q0E0ra29Xe-sacO71Y4jjQ"
  
  iex> defmodule(ESDingoSky, do: use(EntropyString, bits: 64, charset: "dingosky"))
  iex> ESDingoSky.random()
  "kggsodyyynkioyigyoyyoo"
  
  iex> defmodule(DingoskyPuid64, do: use(Puid, bits: 64, chars: "dingosky"))
  iex> DingoskyPuid64.generate()
  "koynkddggokggyinnsogii"
  
  iex> defmodule(UnicodeES92, do: use(EntropyString, bits: 92, charset: "Unicode:Charsət"))
  iex> UnicodeES92.random()
  <<101, 201, 115, 115, 85, 67, 67, 114, 110, 111, 101, 58, 85, 114, 116, 85, 116,
  115, 116, 115, 116, 111, 115>>
  
  iex> defmodule(UnicodePuid92, do: use(Puid, bits: 92, chars: "Unicode:Charsət"))
  iex> UnicodePuid92.generate()
  "iCrnəneCUaiaiəəons:təcss"
  
```

#### Timing

```
Generate 100000 random IDs with 128 bits of entropy using safe64 characters
  Entropy String (CSPRNG) : 2.007152
  Puid           (CSPRNG) : 0.410303

Generate 100000 random IDs with 92 bits of entropy using 8 custom characters
  Entropy String (CSPRNG) : 3.024128
  Puid           (CSPRNG) : 2.03751
```

[TOC](#TOC)

### <a name="gen_reference"></a>[gen_reference](https://dreamconception.com/tech/elixir-simple-way-to-create-random-reference-ids/)

```elixir
defmodule Id do
  def gen_reference() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end
end
```

#### Specification 

  - no argument input
    - fixed string length of 6
  - 1 pre-defined character set
    - fixed entropy of 31 bits
  - does not support custom characters

#### Examples

```elixir
  iex> Id.gen_reference()
  "DABRC1"
  
  iex> bits = Puid.Entropy.bits_for_string!(6, :alphanum_upper)
  iex> defmodule(UpperAlphanumPuid, do: use(Puid, bits: bits, charset: :alphanum_upper))
  iex> UpperAlphanumPuid.generate()
  "2GEIUC"
```

#### Timing

```
Generate 500000 random IDs with 31 bits of entropy using alphanum_upper characters
  gen_reference   (PRNG) : 0.489205
  gen_reference (CSPRNG) : 1.459515
  Puid          (CSPRNG) : 3.564886
```

#### Comments

This solution is clearly faster than `Puid`; however, it has significant shortcomings. The generated strings have a fixed 31 bits of entropy, so there are only 2.15 billion possible IDs. That's fine if you don't need many IDs, but quickly becomes problematic as more are generated. Here are the approximate probabilities of a repeat for a given number of generated IDs:

| Generated | Repeat Risk |
| ---------: | -----: |
| 5,000 | 0.5 % |
| 10,000 | 20 % |
| 50,000 | 44 % |
| 100,000 | 90 % |
| 200,000 | 99 % |

With no flexibility and limited utility, this solution is somewhat an interesting novelty.

[TOC](#TOC)

### <a name="Misc_Random"></a>[Misc.Random](https://hex.pm/packages/misc_random)

#### Specification 

  - specify string length
  - 1 pre-defined character set
  - does not support custom characters
  - does not support CSPRNG

#### Examples

```elixir
  iex> Misc.Random.get_string(22)
  "DGMnEn91xlPYGVOc2lK3Uv"
  
  iex> defmodule(AlphanumPuid, do: use(Puid, charset: :alphanum))
  iex> AlphanumPuid.generate()
  "6bOXdwc5aP2qhRWARtZtpM"
```

#### Timing

```
Generate 50000 random IDs with 128 bits of entropy using alphanum characters
  Misc.Random (PRNG) : 4.277284
  Puid      (CSPRNG) : 0.504289
```

#### Comments

As of __v0.2.6__, `:misc_random` uses the [`:random`](http://www.erlang.org/doc/man/random.html) module. Although not deprecated, the Erlang docs recommend using [`:rand`](http://www.erlang.org/doc/man/rand.html) instead.

[TOC](#TOC)

### <a name="Not_Qwert123"></a>[NotQwerty123](https://hex.pm/packages/not_qwerty123)

#### Specification 

  - specify string length
  - 4 pre-defined character sets 
  - does not support custom characters

#### Examples

```elixir
  iex> len = Puid.Entropy.len_for_bits!(128, :alphanum)
  22
  iex> NotQwerty123.RandomPassword.gen_password(length: len)
  "eM7ZCAtzGTHLQpH85Bav5g"

  iex> defmodule(AlphanumPuid, do: use(Puid, charset: :alphanum))
  iex> AlphanumPuid.generate()
  "RCvrqKohgT5I4bqSHV9sQy"

  iex> len = Puid.Entropy.len_for_bits!(128, :printable_ascii)
  20
  iex> NotQwerty123.RandomPassword.gen_password(length: len, characters: :letters_digits_punc)
  "-y[UNW(qYhHmy1#N'mg,"
  
  iex> defmodule(PrintablePuid, do: use(Puid, charset: :printable_ascii))
  iex> PrintablePuid.generate()
  "8{\"46>7166BQ!vp+PF;3"
```

#### Timing

```
Generate 50000 random IDs with 128 bits of entropy using alphanum characters
  NotQwerty123 (CSPRNG) : 7.079803
  Puid         (CSPRNG) : 0.524233

Generate 50000 random IDs with 128 bits of entropy using printable_ascii characters
  NotQwerty123 (CSPRNG) : 8.090046
  Puid         (CSPRNG) : 0.659449
```

### <a name="Randomizer"></a>[Randomizer](https://hex.pm/packages/randomizer)

#### Specification 

  - specify string length
  - 5 pre-defined character sets 
  - does not support custom characters

#### Examples

```elixir
  iex> len = Puid.Entropy.len_for_bits!(128, :alphanum)
  22
  iex> Randomizer.generate!(len)
  "3VEwz3TXAzxZ1H4zcxIszk"
  
  iex> defmodule(AlphanumPuid, do: use(Puid, charset: :alphanum))
  iex> AlphanumPuid.generate()
  "TgFEtGVBuWZuVfayY60Eww"

  iex> len = Puid.Entropy.len_for_bits!(92, :alpha_lower)
  20
  iex> Randomizer.generate!(len, :downcase)
  "TWRIXlTZwNbRJkanFbXQ"
  
  iex> defmodule(AlphaLowerPuid, do: use(Puid, bits: 92, charset: :alpha_lower))
  iex> AlphaLowerPuid.generate()
  "halpyhdogjafbmipdvsw"
  
```

#### Timing

```
Generate 5000 random IDs with 128 bits of entropy using alphanum characters
   Randomizer   (PRNG) : 1.643205
   Randomizer (CSPRNG) : 16.815926
   Puid       (CSPRNG) : 0.072043
```

[TOC](#TOC)

### <a name="rand_str"></a>[:rand_str](https://hex.pm/packages/rand_str)

#### Specification 

  - specify string length
  - 1 pre-defined character set
  - supports custom characters
     - does not handle unicode

#### Examples

```elixir
  iex> len = Puid.Entropy.len_for_bits!(128, :alphanum)
  22
  iex> :rand_str.get(len)
  'vkG5RkWlioZoYGxguk3xex'

  iex> defmodule(AlphanumPuid, do: use(Puid, charset: :alphanum))
  iex> AlphanumPuid.generate()
  "ov0KKui8RbzTtUgjetKABL"

  iex> len = Puid.Entropy.len_for_bits!(48, "dingosky")
  16
  iex> :rand_str.get(len, 'dingosky')
  'sydyiikiokyynyiy'

  iex> defmodule(DingoskyPuid, do: use(Puid, bits: 48, chars: "dingosky"))
  iex> DingoskyPuid.generate()
  "ksossdgsysyndgko"

  iex> len = Puid.Entropy.len_for_bits!(64, "ŮήιƈŏδεĊħąŕαсτəř")
  16
  iex> :rand_str.get(len, 'ŮήιƈŏδεĊħąŕαсτəř')
  [266, 964, 335, 341, 964, 261, 948, 295, 948, 392, 392, 392, 942, 366, 949, 261]
  
  iex> defmodule(UnicodePuid, do: use(Puid, bits: 64, chars: "ŮήιƈŏδεĊħąŕαсτəř"))
  iex> UnicodePuid.generate()
  "ŮŕδħƈήřŏεřřĊŮąсř"
```

#### Timing

```
Generate 100000 random IDs with 128 bits of entropy using safe64 characters
  :rand_str   (PRNG) : 1.039695
  :rand_str (CSPRNG) : 6.370006
  Puid      (CSPRNG) : 0.293184

Generate 100000 random IDs with 128 bits of entropy using alphanum characters
  :rand_str   (PRNG) : 1.139668
  :rand_str (CSPRNG) : 5.276775
  Puid      (CSPRNG) : 1.247633
```

[TOC](#TOC)

### <a name="SecureRandom"></a>[SecureRandom](https://hex.pm/packages/secure_random)

#### Specification 

  - specified argument is not consistent
  - 3 pre-defined character sets 
  - does not support custom characters

#### Examples

```elixir
  iex> len = 12
  len
  iex> SecureRandom.base64(len)
  "SXkaWlieKm+hlID1"

  iex> bits = Puid.Entropy.bits_for_string!(SecureRandom.base64(len) |> String.length(), :safe64)
  96
  iex> defmodule(Safe64Puid, do: use(Puid, bits: bits, charset: :safe64))
  iex> Safe64Puid.generate()
  "5rd9ql-fJpX6gaA9"

  iex> SecureRandom.urlsafe_base64(len)
  "Y1M2Y2xqTmNEREp2SXdLeg=="
  
```

As of version __0.5.1__, the input argument is not treated consistently. Furthermore, the output of `SecureRandom.urlsafe_base64/1` is not compliant with the [RFC 4648](https://tools.ietf.org/html/rfc4648#section-5) file system and URL safe character set.

#### Timing

```
Generate 500000 random IDs with 128 bits of entropy using hex characters
  SecureRandom (CSPRNG) : 2.14521
  Puid         (CSPRNG) : 1.896126

Generate 500000 random IDs with 128 bits of entropy using safe64 characters
  SecureRandom (CSPRNG) : 3.329939
  Puid         (CSPRNG) : 2.612979
```

[TOC](#TOC)

### <a name="UUID"></a>[UUID](https://hex.pm/packages/uuid):

#### Specification 

  - no input argument
    - fixed string length of 36
  - 1 pre-defined form
    - fixed entropy of 122 bits
  - does not support custom characters

#### Examples

```elixir
  iex> UUID.uuid4()
  "39c8277a-9b9e-4c8d-af50-31c17fd39bd0"
  
  iex> defmodule(HexPuid122, do: use(Puid, bits: 122, charset: :hex))
  iex> HexPuid122.generate()
  "2bc031932cc22c051af9e8b5f598275f"

  iex> defmodule(Safe64Puid122, do: use(Puid, bits: 122, charset: :safe64))
  iex> Safe64Puid122.generate()
  "xJMZ85YkdkYng3yP9W9s"
```

#### Timing

```
Generate 500000 random IDs with 122 bits of entropy using hex
  UUID     : 1.925131
  Puid hex : 1.823116

Generate 500000 random IDs with 122 bits of entropy using safe64
  UUID         : 1.751625
  Puid :safe64 : 1.367201
```

[TOC](#TOC)

