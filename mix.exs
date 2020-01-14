defmodule Puid.Mixfile do
  use Mix.Project

  def project do
    [
      app: :puid,
      version: "1.0.2",
      elixir: "~> 1.8",
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  defp deps do
    [
      {:crypto_rand, "~> 1.0"},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},
      {:entropy_string, "~> 1.1", only: :test},
      {:not_qwerty123, "~> 2.3", only: :test},
      {:misc_random, "~> 0.2.9", only: :test},
      {:rand_str, "~> 1.0", only: :test},
      {:randomizer, "~> 1.1", only: :test},
      {:secure_random, "~> 0.5", only: :test},
      {:uuid, "~> 1.1", only: :test}
    ]
  end

  defp description do
    """
    Fast and efficient generation of cryptographically strong probably unique indentifiers (puid, aka random string) of specified entropy from various character sets.
    """
  end

  defp package do
    [
      maintainers: ["Paul Rogers"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/puid/Elixir",
        "README" => "https://puid.github.io/Elixir/",
        "Docs" => "https://hexdocs.pm/puid/api-reference.html"
      }
    ]
  end
end
