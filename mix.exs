defmodule Puid.Mixfile do
  use Mix.Project

  def project do
    [
      app: :puid,
      version: "2.1.0",
      elixir: "~> 1.8",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:crypto]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.28", only: :dev},
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
