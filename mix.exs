defmodule Puid.MixProject do
  use Mix.Project

  def project do
    [
      app: :puid,
      version: "2.3.2",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: [
        main: "readme",
        source_url: "https://github.com/puid/Elixir",
        homepage_url: "https://puid.github.io/Elixir/",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
      ],
      preferred_cli_env: [
        docs: :dev,
        dialyzer: :dev,
        credo: :dev,
        "hex.docs": :dev
      ]
    ]
  end

  def application do
    [
      extra_applications: [:crypto]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.3", only: [:dev, :test], runtime: false},
      {:entropy_string, "~> 1.3", only: :test},
      {:misc_random, "~> 0.2", only: :test},
      {:nanoid, "~> 2.0", only: :test},
      {:randomizer, "~> 1.1", only: :test},
      {:secure_random, "~> 0.5", only: :test},
      {:ulid, "~> 0.2", only: :test},
      {:uuid, "~> 1.1", only: :test}
    ]
  end

  defp description do
    """
    Simple, fast, flexible and efficient generation of probably unique identifiers (`puid`, aka
    random strings) of intuitively specified entropy using pre-defined or custom characters.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md", "LICENSE"],
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
