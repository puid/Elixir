# Puid

Simple, fast, flexible and efficient generation of probably unique identifiers (`puid`, aka random strings) of intuitively specified entropy using pre-defined or custom characters.

```elixir
  iex> defmodule(RandId, do: use(Puid, chars: :alpha, total: 1.0e5, risk: 1.0e12))
  iex> RandId.generate()
  "YAwrpLRqXGlny"
```

[![Hex Version](https://img.shields.io/hexpm/v/puid.svg "Hex Version")](https://hex.pm/packages/puid) &nbsp; [![License: MIT](https://img.shields.io/npm/l/express.svg)]()

## <a name="TOC"></a>TOC
- [Overview](#Overview)
    - [Usage](#Usage)
    - [Installation](#Installation)
    - [Module API](#ModuleAPI)
    - [Chars](#Chars)
- [Motivation](#Motivation)
    - [What is a random string?](#WhatIsARandomString)
    - [How random is a random string?](#RandomStringEntropy)
    - [Uniqueness](#Uniqueness)
    - [ID randomness](#IDRandomness)
    - [Efficiency](#Efficiency)
    - [Overkill and Under Specify](#Overkill)
- [Comparisons](#Comparisons)
    - [Common Solution](#Common_Solution)
    - [gen_reference](#gen_reference)
    - [Misc.Random](#Misc_Random)
    - [Not_Qwerty123](#Not_Qwerty123)
    - [Randomizer](#Randomizer)
    - [rand_str](#rand_str)
    - [SecureRandom](#SecureRandom)
    - [UUID](#UUID)
- [Efficiencies](#Efficiencies)
- [tl;dr](#tl;dr)


## <a name="Overview"></a>Overview

`Puid` provides fast and efficient generation of random IDs. For the purposes of `Puid`, a random ID is considered a random string used in a context of uniqueness, that is, random IDs are a bunch of random strings that are hopefully unique.

Random string generation can be thought of as a _transformation_ of some random source of entropy into a string _representation_ of randomness. A general purpose random string library used for random IDs should therefore provide user specification for each of the following three key aspects:

1. **Entropy Source**

    What source of randomness is being transformed?
    >`Puid` allows easy specification of the function used for source randomness

2. **ID Characters**

    What characters are used in the ID?
    > `Puid` provides 16 pre-defined character sets, as well as allows custom character designation, including Unicode

3. **ID Randomness**

    What is the resulting “randomness” of the IDs?
    > `Puid` allows an intuitive, explicit specification of ID randomness

[TOC](#TOC)

### <a name="Usage"></a>Usage

Creating a random ID generator using `Puid` is a simple as:

```elixir
  iex> defmodule(RandId, do: use(Puid))
  iex> RandId.generate()
  "8nGA2UaIfaawX-Og61go5A"
```

Options allow easy and complete control of ID generation.

**Entropy Source**

`Puid` uses [:crypto.strong_rand_bytes/1](https://www.erlang.org/doc/man/crypto.html#strong_rand_bytes-1) as the default entropy source. The `rand_bytes` option can be used to specify any function of the form `(non_neg_integer) -> binary` as the source:

```elixir
  iex > defmodule(PrngPuid, do: use(Puid, rand_bytes: &:rand.bytes/1))
  iex> PrngPuid.generate()
  "bIkrSeU6Yr8_1WHGvO0H3M"
```

**ID Characters**

By default, `Puid` use the [RFC 4648](https://tools.ietf.org/html/rfc4648#section-5) file system & URL safe characters. The `chars` option can by used to specify any of 16 [pre-defined character sets](#Chars) or custom characters, including Unicode:

```elixir
  iex> defmodule(HexPuid, do: use(Puid, chars: :hex))
  iex> HexPuid.generate()
  "13fb81e35cb89e5daa5649802ad4bbbd"

  iex> defmodule(DingoskyPuid, do: use(Puid, chars: "dingosky"))
  iex> DingoskyPuid.generate()
  "yiidgidnygkgydkodggysonydodndsnkgksgonisnko"
  
  iex> defmodule(DingoskyUnicodePuid, do: use(Puid, chars: "dîñgø$kyDÎÑGØßK¥", total: 2.5e6, risk: 1.0e15))
  iex> DingoskyUnicodePuid.generate()
  "øßK$ggKñø$dyGîñdyØøØÎîk"
  
```

**ID Randomness**

Generated IDs have 128-bit entropy by default. `Puid` provides a simple, intuitive way to specify ID randomness by declaring a `total` number of possible IDs with a specified `risk` of a repeat in that many IDs:

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

[TOC](#TOC)

### <a name="Installation"></a>Installation

Add `puid` to `mix.exs` dependencies:

  ```elixir
  def deps,
    do: [
      {:puid, "~> 2.0"}
    ]
  ```

Update dependencies

  ```bash
  mix deps.get
  ```

### <a name="ModuleAPI"></a>Module API

`Puid` modules have two functions:

**`generate/0`**

  Generates a **`puid`**
	
**`info/0`**

  Returns a `Puid.Info` structure consisting of
    
  - Source characters
  - Name of pre-defined `Puid.Chars` or `:custom`
  - Entropy bits per character
  - Total entropy bits
    - May be larger than the specified `bits` since it is a multiple of the entropy bits per
     character
  - Entropy representation efficiency
    - Ratio of the **`puid`** entropy to the bits required for **`puid`** string representation
  - Entropy source function
  - **`puid`** string length

### <a name="Chars"></a>Chars

There are 16 pre-defined character sets:

| Name | Characters |
| :- | :- |
| :alpha | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz |
| :alpha\_lower | abcdefghijklmnopqrstuvwxyz |
| :alpha\_upper | ABCDEFGHIJKLMNOPQRSTUVWXYZ |
| :alphanum | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 |
| :alphanum\_lower | abcdefghijklmnopqrstuvwxyz0123456789 |
| :alphanum\_upper | ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 |
| :base32 | ABCDEFGHIJKLMNOPQRSTUVWXYZ234567 |
| :base32\_hex | 0123456789abcdefghijklmnopqrstuv |
| :base32\_hex\_upper | 0123456789ABCDEFGHIJKLMNOPQRSTUV |
| :decimal | 0123456789 |
| :hex | 0123456789abcdef |
| :hex\_upper | 0123456789ABCDEF |
| :safe\_ascii |  !#$%&()\*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^\_abcdefghijklmnopqrstuvwxyz{\|}~ |
| :safe32 | 2346789bdfghjmnpqrtBDFGHJLMNPQRT |
| :safe64 | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_ |
| :symbol | !#$%&()*+,-./:;<=>?@[]^_{\|}~ |


Any `String` or `charlist` of up to 256 unique characters can be used for **`puid`** generation. Custom characters set are optimized in the same manner as the pre-defined character sets.

[TOC](#TOC)

## <a name="Motivation"></a>Motivation

Developers frequently need random strings in applications ranging from long-term (e.g., data store keys) to short-term (e.g. DOM IDs on a web page). These IDs are, of course, of secondary concern. No one wants to think about them much, they just want to be easy to generate.

But developers *should* think about the random strings they use. The generation of random IDs is a design choice, and just like any other design choice, that choice should be explicit in nature and based on a familiar with why such choices are made. Yet a cursory review of random string libraries, as well as random string usage in many applications, yields a lack of clarity that belies careful consideration.

[TOC](#TOC)

### <a name="WhatIsARandomString"></a>What is a random string?

Although this may seem to have an obvious answer, there is actually a key, often overlooked subtlety: a random string *is not random* in and of itself. To understand this, we need to understand [*entropy*](https://en.wikipedia.org/wiki/Entropy_(information_theory)) as it relates to computers.

A somewhat simplistic statement for entropy from information theory is: _entropy is a measure of uncertainty in the possible outcomes of an event_. Given the base 2 system inherent in computers, this uncertainty naturally maps to a unit of bits (known as Shannon entropy). So we see statements like "_this random string has 128 bits of entropy_". But here is the subtlety:

 > _**A random string does not have entropy**_
 
Rather, a random string represents _captured_ entropy, entropy that was produced by _some other_ process. For example, you cannot look at the hex string **`"18f6303a"`** and definitively say it has 32 bits of entropy. To see why, suppose you run the following code snippet and get **`"18f6303a"`**:

```elixir
  iex> rand_id = fn -> (if (:rand.uniform(2) == 2), do: "18f6303a", else: "1") end
  iex> rand_id.()
  "18f6303a"
```

The entropy of the resulting string **`"18f6303a"`** is 1 bit. That's it; 1 bit. The same entropy as when the outcome **`"1"`** is observed. In either case, there are two equally possible outcomes and the resulting entropy is therefore 1 bit. It's important to have this clear understanding:

 > _**Entropy is a measure in the uncertainty of an event, independent of the representation of that uncertainty**_

In information theory you would state the random process emits two symbols, **`18f6303a`** and **`1`**, and the outcome is equally likely to be either symbol. Hence there is 1 bit of entropy in the process. The symbols don't matter. It would be much more likely to see the symbols **`T`** and **`F`**, or **`0`** and **`1`**, or even **`ON`** and **`OFF`**, but regardless, the process _produces_ 1 bit of entropy and symbols used to _represent_ that entropy do not effect the entropy itself.

#### Entropy source

Random string generators need an external source of entropy and typically use a system resource for that entropy. In Elixir, this could be a [:rand](https://www.erlang.org/doc/man/rand.html) module function or [:crypto.strong_rand_bytes/1](https://www.erlang.org/doc/man/crypto.html#strong_rand_bytes-1). Nonetheless, it is important to appreciate that the properties of the generated random strings depend on the characteristics of the entropy source. For example, whether a random string is suitable for use as a secure token depends on the security characteristics of the entropy source, not on the string representation of the token.

#### ID characters

As noted, the characters (symbols) used for a random string do not determine the entropy. However, the number of unique characters available does. Under the assumption that each character is equally probable (which maximizes entropy) it is easy to show the entropy per character is a constant log<sub>2</sub>(N), where `N` is of the number of characters available.


#### ID randomness

String randomness is determined by the entropy per character times the number of characters in the string. The *quality* of that randomness is directly tied to the quality of the entropy source. The *randomness* depends on the number of available characters and the length of the string.

And finally we can state: a random string is a character representation of captured entropy.

[TOC](#TOC)

### <a name="Uniqueness"></a>Uniqueness

The goal of `Puid` is to provide simple, intuitive random ID generation using random strings. As noted above, we can consider random string generation as the _transformation_ of system entropy into a character _representation_, and random IDs as being the use of such random strings to represent unique IDs. There is a catch though; a big catch:

> _**Random strings do not produce unique IDs**_


Recall that entropy is the measure of uncertainty in the possible outcomes of an event. It is critical that the uncertainty of each event is *independent* of all prior events. This means two separate events *can* produce the same result (i.e., the same ID); otherwise the process isn't random. You could, of course, compare each generated random string to all prior IDs and thereby achieve uniqueness. But some such post-processing must occur to ensure random IDs are truly unique.

Deterministic uniqueness checks, however, incur significant processing overhead and are rarely used. Instead, developers (knowingly?) relax the requirement that random IDs are truly, deterministically unique for a much lesser standard, one of probabilistic uniqueness. We "trust" that randomly generated IDs are unique by virtue of the chance of a repeated ID being very low.

And once again, we reach a point of subtlety. (And we thought random strings were easy!) The "trust" that randomly generated IDs are unique actually turns entropy as it's been discussed thus far on it's head. Instead of viewing entropy as a measure of uncertainty in the *generation* of IDs, we consider entropy as a measure of the probability that no two IDs will be the same. To be sure, we want this probability to be very low, but for random strings it *cannot be zero*! And to be clear, *entropy is not such a measure*. Not directly anyway. Yes, the higher the entropy, the lower the probability, but it takes a bit of math to correlate the two in a proper manner. (Don't worry, `Puid` takes care of this math for you).

Furthermore, the probable uniqueness of ID generation is always in some limited context. Consider IDs for a data store. You don't care if a generated ID is the same as an ID used in another data store in another application in another company in a galaxy far, far away. You care that the ID is (probably) unique within the context of your application.

To recap, random string generation does not produce unique IDs, but rather, IDs that are probably unique (within some context). That subtlety is important enough it's baked into the name of `Puid`. And it is  fully at odds with the naming of a version 4 `uuid`. Why? Because being generated via a random process means a `uuid` *cannot be unique*. As a corollary, it can't be universal either. As noted above, we don't care about the universal part anyway, but the fact remains, a `uuid` isn't **uu**.

[TOC](#TOC)

### <a name="IDRandomness"></a>ID randomness

So what does the statement "*these IDs have 122 bits of entropy*" actually mean? Entropy is a measure of uncertainty after all, and we're concerned that our IDs be unique, probably unique anyway. So what does "122 bits of entropy" mean for the probable uniqueness of IDs?

First, let's be clear what it _doesn't_ mean. We're concerned with uniqueness of a bunch of IDs in a certain context. The randomness of _any one_ of those ID isn't the real concern. Yes, we can say "*given 122 bits of entropy*" each ID has a probability of 2<sup>-122</sup> of occurring. And yes, that certainly makes the occurrence of any particular ID rare. But with respect to the uniqueness of IDs, it simply isn't "enough" to tell the whole story.

And here again we hit another subtlety. It turns out the question, as posed, is underspecified, i.e. it is not specific enough to be answered. To properly determine how entropy relates to the probable uniqueness of IDs, we need to specify *how many* IDs are to be generated in a certain context. Only then can we determine the probability of generating unique IDs. So our question really needs to be: given **N** bits of entropy, what is the probability of uniqueness in **T** random IDs?

Fortunately, there is a mathematical correlation between entropy and the probability of uniqueness. This correlation is often explored via the [Birthday Paradox](https://en.wikipedia.org/wiki/Birthday_problem#Cast_as_a_collision_problem). Why paradox? Because the relationship, when cast as a problem of unique birthdays in some number of people, is initially quite surprising. But nonetheless, the relationship exists, it is well-known, and `Puid` will take care of the math for us.

At this point we can now note that rather than say "*these IDs have **N** bits of entropy*", we actually want to say "_generating **T** of these IDs has a risk **R** of a repeat_". And fortunately, `Puid` allows straightforward specification of that very statement for random ID generation. Using `Puid`, you can easily specify "*I want **T** random IDs with a risk **R** of repeat*". `Puid` will take care of using the correct entropy in efficiently generating the IDs.

[TOC](#TOC)

### <a name="Efficiency"></a>Efficiency

The efficiency of generating random IDs has no bearing on the statistical characteristics of the IDs themselves. But who doesn't care about efficiency? Unfortunately, most random string generation, it seems.

#### Entropy source

As previously stated, random ID generation is basically a *transformation* of an entropy source into a character *representation* of captured entropy. But the entropy of the source and the entropy of the captured ID *is not the same thing*.

To understand the difference, we'll investigate an example that is, surprisingly, quite common. Consider the following strategy for generating random strings: using a fixed list of **k** characters, use a random uniform integer **i**, `0 <= i < k`, as an index into the list to select a character. Repeat this **n** times, where **n** is the length of the desired string. In Elixir this might look like:

```elixir
iex> chars = Enum.to_list(?a..?z)
iex> k = length(chars)
iex> common_id = fn n -> for(_ <- 1..n, do: :rand.uniform(k) - 1)
       |> Enum.map(&(chars |> Enum.at(&1)))
       |> List.to_string()
     end
iex> common_id.(8)
"wzqkgzid"
```

First, consider the amount of source entropy used in the code above. According to the Erlang [:rand](https://www.erlang.org/doc/man/rand.html) docs, using the default `exsss` algorithm,  the amount of entropy in each call to `:rand.uniform/1` is 58-bits. So generating an 8 character ID consumes 8 * 58 = 464 bits of source entropy.

Second, consider how much entropy was captured by the ID. Given there are 26 available characters, each character represents log<sub>2</sub>(26) = 4.7 bits of entropy. So each generated ID represents 8 * 4.7 = 37.6 bits of entropy.

Hmmm. That means the ratio of ID entropy to source entropy is 37.6 / 464 = 0.081, or a whopping **8.1%**. That's not an efficiency most developers would be comfortable with. Granted, this is a particularly egregious example, but most random ID generation suffers such inefficient use of source entropy.

Without delving into the specifics (see the code?), `Puid` employs various means to maximize the use of source entropy. As comparison, `Puid` uses **87.5%** of source entropy in generating random IDs using lower case alpha characters. For character sets with counts equal a power of 2, `Puid` uses 100% of source entropy.

#### Speed of generation

There is, of course, another inefficiency involved in the above code. It is quite slow. `Puid` is comparatively much, much faster. The project includes timing tests that show `Puid` is as fast (and often significantly faster) than other random string generators.

Note: Kudos to the Elixir team's implementation of `Base`. The strategies used for speed in that module were generalized and adapted to produce the speed achieved by `Puid`.

#### Characters

As previous noted, the entropy of a random string is equal to the entropy per character times the length of the string. Using this value leads to an easy calculation of **entropy representation efficiency** (`ere`). We can define `ere` as the ratio of random string entropy to the number of bits required to represent the string. For example, the lower case alphabet has an entropy per character of 4.7, so an ID of length 8 using those characters has 37.6 bits of entropy. Since each lower case character requires 1 byte, this leads to an `ere` of 37.6 / 64 = 0.59, or 59%. (Note: Elixir strings are UTF-8 encoded, so non-ascii characters occupy more than 1 byte).

<a name="UUIDCharacters"></a>

The total entropy of a string is the product of the entropy per character times the string length *only* if each character in the final string is equally probable. This is always the case for `Puid`, and is usually the case for other random string generators. There is, however, a notable exception: the version 4 string representation of a `uuid`. As defined in [RFC 4122, Section 4.4](https://tools.ietf.org/html/rfc4122#section-4.4), a v4 `uuid` uses a total of 32 hex and 4 hyphen characters. Although the hex characters can represent 4 bits of entropy each, 6 bits of the hex representation in a `uuid` are actually fixed, so there is only `32*4 - 6 = 122`-bits of entropy (not 128). The 4 fixed-position hyphen characters contribute zero entropy. So a 36 character `uuid` has an `ere` of `122 / (36*8) = 0.40`, or **40%**. Compare that to, say, the default `Puid` generator, which has slightly higher entropy (132 bits) and yet yields an `ere` of 0.75, or **75%**. Who doesn't love efficiency?

[TOC](#TOC)

### <a name="Overkill"></a>Overkill and Under Specify


#### Overkill

Random string generation is plagued by overkill and under specified usage. Consider the all too frequent use of `uuid`s as random strings. The rational is seemingly that the probability of a repeated `uuid` is low. Yes, it is admittedly low, but is that sufficient reason to use a `uuid` without further thought? For example, suppose a `uuid` is used as a key in a data store that will have  at most a thousand items. What is the probability of a repeated `uuid` in this case? It's 1 in a nonillion. That's 10^30, or 1 followed by 30 zeros, or million times the estimated number of stars in the universe. Really? Doesn't that seem a bit overkill? Do really you need that level of assurance? And if so, why stop there? Why not concatenate two `uuid`s and get an even more ridiculous level of "assurance".  

Or why not be a bit more reasonable and think about the problem for a moment. Suppose you accept a 1 in 10^15 risk of repeat. That's still a *really* low risk. Ah, but wait, to do that you can't use a `uuid`, because `uuid` generation isn't flexible.

You could generate the IDs by determining the actual amount of ID entropy required (it's 68.76 bits), selecting some set of characters, calculate the string length necessary given those characters, and finally generate the IDs as outlined in the earlier common ID generation scheme.

Whew, maybe that's another reason developers tend to use uuids. That seems like a lot of effort.

Ah, but there is another way. You could very easily use `Puid` to generate such IDs:

```elixir
  iex> defmodule(DbId, do: use(Puid, total: 1_000, risk: 1.0e15))
  iex> DbId.generate()
  "sJmzTrFELLls"
```

The resulting IDs have 72 bits of entropy. But guess what? You don't care. What you care is having explicitly stated you expect to have 1000 IDs and your level of repeat risk is 1 in a quadrillion. It's right there in the code. And as added bonus, the IDs are only 12 characters long, not 36. Who doesn't like ease, control and efficiency?

#### Under specify

Another head-scratcher in schemes that generate random strings is using an API that explicitly declares string length. Why is this troubling? Because that declaration doesn't specify the actual amount of desired randomness, either needed or achieved. Suppose you are tasked with maintaining code that is using random IDs of 15 characters composed of digits and lower alpha characters. Why are the IDs 15 characters long? Without code comments, you have no idea. And without knowing how many IDs are expected, you can't determine the risk of a repeat, i.e., you can't even make a statement about how random the random IDs actually are! Was 15 chosen for a reason, or just because it made the IDs look good?


Now, suppose you are tasked to maintain this code:

```elixir
  defmodule(RandId, do: use(Puid, total: 500_000, risk: 1.0e12, chars: :alphanum_lower))
```

Hmmm. Looks like there are 500,000 IDs expected and the repeat risk is 1 in a trillion. No guessing. The code is explicit. Oh, and by the way, the IDs are 15 characters long. But who cares? It's the ID randomness that matters, not the length.


[TOC](#TOC)

## <a name="Comparisons"></a>Comparisons

There are a number of existing Elixir solutions for the generation of random IDs. Whether explicit or implicit, each solution involves:

1. **An entropy source**
 A library should provide an easy and flexible means of specifying the source of randomness. `Puid` allows any function of the form `(non_neg_integer) -> binary` to be used.
2. **Characters to be used**
Some libraries fix the characters used; others allows specifying the characters. `Puid` provides pre-defined character sets as well as custom characters, including Unicode.
3. **The amount of resulting randomness**
Some libraries fix the amount of randomness per ID; others specifying the randomness though in an implicit, indirect fashion of ID length. Only `Puid` provides a simple, intuitive means of specifying entropy via the declaration of a _**total**_ number of IDs with an explicit _**risk**_ of repeat.
4. **Efficiency of generation**
Most libraries are quite inefficient in converting source entropy into the randomness represented by the IDs themselves. `Puid` is highly optimized to convert as much of the original entropy into ID randomness as possible.
5. **Speed of generation**
Schemes of random ID generation have significant variation with regard to speed. `Puid` is optimized to be as fast or faster than other solutions.

The following provides comments and timings in comparing `Puid` to other Elixir solutions of generating random IDs. Where appropriate, both PRNG and CSPRNG timings are shown.

The code used for **Timing** output is in the project `test/timing.exs` file.

[TOC](#TOC)

### <a name="Common_Solution"></a>Common Solution

The common solution to generating random strings in just about every computer language boils down to the same strategy: for an string of a specified length, randomly index into a list of characters to build the string.

Specify string length is, however, misguided. You don't care about string length, you care about uniqueness. The fact that most usages of the common solution simply chose a list of characters and pick the ID length out of thin air without really understanding or analyzing the true entropy need is troubling. Furthermore, the solution is typically inefficient and slow.

#### Timing

```
Generate 100000 random IDs with 128 bits of entropy using alphanumeric characters

  Common Solution   (PRNG) : 4.977226
  Puid              (PRNG) : 0.831748

  Common Solution (CSPRNG) : 8.435073
  Puid            (CSPRNG) : 0.958437
```

[TOC](#TOC)

### <a name="gen_reference"></a>gen_reference

Though [gen_reference](https://dreamconception.com/tech/elixir-simple-way-to-create-random-reference-ids/) is quite fast, it has both a fixed character set (upper alpha and digits) and a fixed randomness of 31 bits of entropy per ID.

#### Timing

```code
Generate 500000 random IDs with 31 bits of entropy using alphanum_upper characters

  gen_reference   (PRNG) : 0.16537
  Puid            (PRNG) : 3.59646

  gen_reference (CSPRNG) : 0.977972
  Puid          (CSPRNG) : 3.638086
```

Compared to `Puid` CSPRNG generation using :safe32 characters, the timing is much closer to the same:

```code
Generate 500000 random IDs with 31 bits of entropy using :safe32 characters

  gen_reference (CSPRNG) : 0.923077
  Puid safe32   (CSPRNG) : 1.085479
```

The real issue, however, is the fixed entropy of 31 bits per ID. This provides 2.15 billion possible IDs, and although that may seem like a lot, the following highlights the potentially surprising probability of a repeat in using such IDs:

| Generated | Repeat Risk |
| --------: | ----------: |
|     5,000 |       0.6 % |
|    10,000 |       2.3 % |
|    50,000 |        44 % |
|   100,000 |        90 % |
|   200,000 |        99 % |

Ouch. With no flexibility and limited utility, `gen_reference` is basically an interesting novelty.

[TOC](#TOC)

### <a name="Misc.Random"></a>Misc.Random

Admittedly, [Misc.Random](https://hex.pm/packages/misc_random) is for generating random file names and is not suitable for general random IDs. But it is still quite slow. Entropy is indirectly specified through string length.

#### Timing

```code
Generate 50000 random IDs with 128 bits of entropy using alphanum characters

  Misc.Random (PRNG) : 12.196646
  Puid        (PRNG) : 0.295741

  Misc.Random (CSPRNG) : 11.9858
  Puid        (CSPRNG) : 0.310417
```

[TOC](#TOC)

### <a name="Not_Qwerty123"></a>Not_Qwerty123

Maintenance of [NotQwerty123](https://hex.pm/packages/not_qwerty123) has terminated. IDs are limited to four pre-defined character sets and entropy is indirectly specified through string length. And like most solutions, it's slow.

#### Timing

```code
Generate 50000 random IDs with 128 bits of entropy using alphanum characters

  NotQwerty123 (CSPRNG) : 3.74295
  Puid         (CSPRNG) : 0.310214

Generate 50000 random IDs with 128 bits of entropy using no_escape characters

  NotQwerty123 (CSPRNG) : 3.920867
  Puid         (CSPRNG) : 0.438073
```

[TOC](#TOC)

### <a name="Randomizer"></a>Randomizer

[Randomizer](https://hex.pm/packages/randomizer) IDs are limited to five pre-defined character sets and entropy is indirectly specified through string length.

#### Timing

```
Generate 100000 random IDs with 128 bits of entropy using alphanum characters

  Randomizer   (PRNG) : 1.201281
  Puid         (PRNG) : 0.829199

  Randomizer (CSPRNG) : 4.329881
  Puid       (CSPRNG) : 0.807226
```

[TOC](#TOC)

### <a name="SecureRandom"></a>SecureRandom

[SecureRandom](https://hex.pm/packages/secure_random) is admittedly geared toward three specific scenarios of random ID generation and is not a general solution. Custom characters are not supported and, depending on the call used, entropy is either fixed or indirectly specified through string length. `Puid` matches `SecureRandom` speed while providing much more flexibility and explicit entropy declaration.

#### Timing

```
Generate 500000 random IDs with 128 bits of entropy using hex characters

  SecureRandom (CSPRNG) : 1.19713
  Puid         (CSPRNG) : 1.187726

Generate 500000 random IDs with 128 bits of entropy using safe64 characters

  SecureRandom (CSPRNG) : 2.103798
  Puid         (CSPRNG) : 1.806514
```

[TOC](#TOC)

### <a name="UUID"></a>UUID

`UUID` is a misnomer: a `uuid` is neither universal nor unique. As stated early, we don't ever need our context to be "universal" anyway. Uniqueness within some limited context is desired, of course. And that uniqueness is always probable and never truly unique.

With respect to random ID representation, [UUID](https://hex.pm/packages/uuid) is an [inefficient](#UUIDCharacters) one-trick pony. `Puid` provides much more flexibility, an easy means of explicitly specifying what entropy is really needed, and speed equal to UUID generation.

#### Timing

```code
Generate 500000 random IDs with 122 bits of entropy using hex
  UUID     : 1.925131
  Puid hex : 1.823116

Generate 500000 random IDs with 122 bits of entropy using safe64
  UUID        : 1.751625
  Puid safe64 : 1.367201
```

[TOC](#TOC)

### <a name="Efficiencies"></a>Efficiencies

`Puid` employs a number of efficiencies for random ID generation:

- Only the number of bytes necessary to generate the next `puid` are fetched from the entropy source
- Each `puid` character is generated by slicing the minimum number of entropy bits possible
- Any left-over bits are carried forward and used in generating the next `puid`
- All characters are equally probable to maximize captured entropy
- Only characters that represent entropy are present in the final ID 
- Easily specified `total/risk` ensures ID are only as long as actually necessary

[TOC](#TOC)

### <a name="tl;dr"></a>tl;dr

`Puid` is a simple, fast, flexible and efficient random ID generator:

- **Ease**

    Random ID generator specified in one line of code
    
- **Flexible**

    Full control over entropy source, ID characters and amount of ID randomness
    
- **Secure**

    Defaults to a secure source of entropy and at least 128 bits of ID entropy

- **Efficient**

    Maximum use of system entropy
    
- **Compact**

    ID strings represent maximum entropy for characters used

- **Fast**

    As fast or faster than other solutions

- **Explicit**

    Clear specification of ID generation
    

```elixir
  iex> defmodule(RandId, do: use(Puid, chars: :safe32, total: 10.0e6, risk: 1.0e15))
  iex> RandId.generate()
  "mGMFj4fg2MGHQFdjGFjR"
```

[TOC](#TOC)
