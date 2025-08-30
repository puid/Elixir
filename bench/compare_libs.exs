# Run with:
#   MIX_ENV=test mix run bench/compare_libs.exs

# Defaults: env var TRIALS=50000

trials = System.get_env("TRIALS", "50000") |> String.to_integer()

defmodule(Safe64Puid128, do: use(Puid, chars: :safe64))
defmodule(Safe64Puid128PRNG, do: use(Puid, chars: :safe64, rand_bytes: &:rand.bytes/1))

defmodule(AlphaNumPuid128, do: use(Puid, chars: :alphanum))
defmodule(HexPuid128, do: use(Puid, chars: :hex))

common_solution = fn len, chars ->
  count = String.length(chars)

  1..len
  |> Enum.map(fn _ -> String.at(chars, :rand.uniform(count) - 1) end)
  |> Enum.join()
end

scenarios =
  %{}
  |> Map.put("Puid safe64 (CSPRNG)", fn ->
    Enum.each(1..trials, fn _ -> Safe64Puid128.generate() end)
  end)
  |> Map.put("Puid safe64 (PRNG)", fn ->
    :rand.seed(:exsss)
    Enum.each(1..trials, fn _ -> Safe64Puid128PRNG.generate() end)
  end)
  |> Map.put("Puid alphanum (CSPRNG)", fn ->
    Enum.each(1..trials, fn _ -> AlphaNumPuid128.generate() end)
  end)
  |> Map.put("Puid hex (CSPRNG)", fn ->
    Enum.each(1..trials, fn _ -> HexPuid128.generate() end)
  end)

scenarios =
  if Code.ensure_loaded?(EntropyString) do
    defmodule(Safe64ES, do: use(EntropyString, chars: :charset64))

    Map.put(scenarios, "EntropyString safe64", fn ->
      Enum.each(1..trials, fn _ -> Safe64ES.random() end)
    end)
  else
    scenarios
  end

scenarios =
  if Code.ensure_loaded?(SecureRandom) do
    Map.put(scenarios, "SecureRandom urlsafe_base64", fn ->
      Enum.each(1..trials, fn _ -> SecureRandom.urlsafe_base64() end)
    end)
  else
    scenarios
  end

scenarios =
  if Code.ensure_loaded?(UUID) do
    Map.put(scenarios, "UUID v4 (string)", fn ->
      Enum.each(1..trials, fn _ -> UUID.uuid4() end)
    end)
  else
    scenarios
  end

scenarios =
  if Code.ensure_loaded?(Nanoid) do
    Map.put(scenarios, "Nanoid (CSPRNG)", fn ->
      Enum.each(1..trials, fn _ -> Nanoid.generate() end)
    end)
  else
    scenarios
  end

scenarios =
  if Code.ensure_loaded?(Randomizer) do
    Map.put(scenarios, "Randomizer alphanum 22", fn ->
      Enum.each(1..trials, fn _ -> Randomizer.generate!(22) end)
    end)
  else
    scenarios
  end

alphanum_chars = AlphaNumPuid128.info().characters
alphanum_len = AlphaNumPuid128.info().length

scenarios =
  Map.put(scenarios, "Common Solution alphanum", fn ->
    Enum.each(1..trials, fn _ -> common_solution.(alphanum_len, alphanum_chars) end)
  end)

IO.puts("Bench trials: #{trials}")

Benchee.run(scenarios,
  time: 2,
  warmup: 0,
  memory_time: 0,
  parallel: 1
)
