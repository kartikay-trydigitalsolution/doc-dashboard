defmodule FirmtechApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :firmtech_api,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {FirmtechApi.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.20"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.3"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:httpoison, "~> 2.0"},
      {:goth, "~> 1.4"},
      {:ex_firebase_auth, git: "https://github.com/acrolink/ExFirebaseAuth.git"},
      {:joken, "~> 2.6"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_lambda, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws_dynamo, "~> 4.2"},
      {:hackney, "~> 1.18"},
      {:gen_smtp, "~> 1.0"},
      {:ecto_enum, "~> 1.4"},
      {:flop, "~> 0.26.1"},
      {:ecto_boot_migration, "~> 0.3.0"},
      {:corsica, "~> 2.0"},
      # For JWK/crypto operations
      {:jose, "~> 1.11"},
      {:exceed, "~> 0.6"},
      {:oban, "~> 2.19"},
      {:igniter, "~> 0.5", only: [:dev]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
