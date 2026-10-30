# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :firmtech_api, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10],
  repo: FirmtechApi.Repo

config :firmtech_api,
  ecto_repos: [FirmtechApi.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :firmtech_api, FirmtechApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: FirmtechApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: FirmtechApi.PubSub,
  live_view: [signing_salt: "J1auj0lr"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :firmtech_api, FirmtechApi.Mailer, adapter: Swoosh.Adapters.Local

# mailer
config :firmtech_api, FirmtechApi.Mailer,
  adapter: Swoosh.Adapters.AmazonSES,
  region: System.get_env("AWS_REGION"),
  access_key: System.get_env("AWS_ACCESS_KEY"),
  secret: System.get_env("AWS_SECRET_KEY")

# Configure Swoosh API Client
config :swoosh, :api_client, Swoosh.ApiClient.Finch

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_KEY"}, :instance_role],
  region: {:system, "AWS_REGION"}

# firebase config
config :firmtech_api, firebase_project_id: System.get_env("FIREBASE_PROJECT_ID", "")

config :ex_firebase_auth,
       :issuer,
       "https://securetoken.google.com/" <> System.get_env("FIREBASE_PROJECT_ID", "")

config :flop, repo: FirmtechApi.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
