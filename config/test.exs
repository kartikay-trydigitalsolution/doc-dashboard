import Config
config :firmtech_api, Oban, testing: :manual

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :firmtech_api, FirmtechApi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "firmtech_api_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :firmtech_api, FirmtechApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "uzwacg2n3u6aK+aZFWG8mFCs9M3MgesA2/9DInVS9fONyYGx/kG8UN7Gjwn9YwFs",
  server: false

# In test we don't send emails
config :firmtech_api, FirmtechApi.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
