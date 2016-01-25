defmodule Vchat.Mixfile do
  use Mix.Project

  def project do
    [app: :vchat,
     version: "0.0.3",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     deps: deps]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Vchat, []},
     applications: [:phoenix, :phoenix_html, :cowboy, :xmerl, :floki, :logger, :gettext,
                    :phoenix_ecto, :mariaex, :mailgun, :comeonin, :connection, :colorful,  :httpoison ]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.1.1"},
     {:phoenix_ecto, "~> 2.0"},
     {:mariaex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.3"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:cowboy, "~> 1.0"},
     {:comeonin, "~> 2.0"},
     {:mailgun, "~> 0.1.2"},
     {:gettext, "~> 0.9"},
     {:colorful, "~> 0.6.0"},
     { :ex_doc, github: "elixir-lang/ex_doc" },
     {:earmark, ">= 0.0.0"},
     {:httpoison, "~> 0.8.0"},
     {:floki, "~> 0.7.1"},
     {:exrm, "~> 1.0.0-rc7"}
   ]
  end

  # Aliases are shortcut or tasks specific to the current project. 
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"]]
  end
end
