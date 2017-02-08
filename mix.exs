defmodule ElixirAle.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_ipa,
     version: "1.0.0",
     elixir: "~> 1.4",
     name: "elixir_ipa",
     description: description(),
     package: package(),
     source_url: "https://github.com/billysvensson/elixir_ipa",
     compilers: [:elixir_make] ++ Mix.compilers,
     make_clean: ["clean"],
     docs: [extras: ["README.md"]],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:gproc]]
  end

  defp description do
    """
    Elixir access to hardware I/O interfaces such as GPIO, I2C, and SPI.
    """
  end

  defp package do
    %{files: ["lib", "src/*.[ch]", "src/linux/i2c-dev.h", "mix.exs", "README.md", "LICENSE", "Makefile"],
      maintainers: ["Billy Svensson"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub Elixir IPA" => "https://github.com/billysvensson/elixir_ipa",
               "GitHub Elixir ALE" => "https://github.com/fhunleth/elixir_ale",
               "GitHub Erlang/ALE" => "https://github.com/esl/erlang_ale"}}
  end

  defp deps do
    [
      {:gproc, "~> 0.6.1"},
      {:elixir_make, "~> 0.4"},
      {:ex_doc, "~> 0.14.3", only: :dev},
      {:credo, "~> 0.5.1", only: [:dev, :test]},
      {:dialyze, "~> 0.2.1", only: [:dev, :test]}
    ]
  end

end
