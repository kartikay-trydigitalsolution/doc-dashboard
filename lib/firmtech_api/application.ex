defmodule FirmtechApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # run migrations
    {:ok, _} = EctoBootMigration.migrate(:firmtech_api)

    # firebase admin SDK
    credentials =
      "GOOGLE_APPLICATION_CREDENTIALS"
      |> System.fetch_env!()
      |> File.read!()
      |> Jason.decode!()

    source = {:service_account, credentials}

    children = [
      FirmtechApiWeb.Telemetry,
      FirmtechApi.Repo,
      FirmtechApi.Cache,
      {Oban, Application.fetch_env!(:firmtech_api, Oban)},
      {DNSCluster, query: Application.get_env(:firmtech_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FirmtechApi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: FirmtechApi.Finch},
      # Start a worker by calling: FirmtechApi.Worker.start_link(arg)
      # {FirmtechApi.Worker, arg},
      # Start to serve requests, typically the last entry
      FirmtechApiWeb.Endpoint,
      {Goth, name: FirmtechApi.Goth, source: source}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FirmtechApi.Supervisor]
    result = Supervisor.start_link(children, opts)

    case result do
      {:ok, _pid} -> print_start_banner()
      {:error, _reason} -> :ok
    end

    result
  end

  defp print_start_banner do
    endpoint = FirmtechApiWeb.Endpoint
    url_config = endpoint.config(:url)
    http_config = endpoint.config(:http)
    scheme = url_config[:scheme] || "http"
    host = url_config[:host] || "localhost"
    port = http_config[:port]

    banner = """
    \e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m
    \e[32m  ███████╗██╗██████╗ ███╗   ███╗████████╗███████╗ ██████╗██╗  ██╗
    \e[32m  ██╔════╝██║██╔══██╗████╗ ████║╚══██╔══╝██╔════╝██╔════╝██║  ██║
    \e[32m  █████╗  ██║██████╔╝██╔████╔██║   ██║   █████╗  ██║     ███████║
    \e[32m  ██╔══╝  ██║██╔══██╗██║╚██╔╝██║   ██║   ██╔══╝  ██║     ██╔══██║
    \e[32m  ██║     ██║██║  ██║██║ ╚═╝ ██║   ██║   ███████╗╚██████╗██║  ██║
    \e[32m  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝\e[0m
    \e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m

    \e[1;32m  ✔ SERVER STARTED SUCCESSFULLY\e[0m
    \e[90m  ─────────────────────────────────────────────\e[0m
    \e[90m  Environment :\e[0m \e[33m#{Application.get_env(:firmtech_api, :env) || Mix.env() || "dev"}\e[0m
    \e[90m  URL         :\e[0m \e[36m#{scheme}://#{host}:#{port}\e[0m
    \e[90m  Port        :\e[0m \e[36m#{port}\e[0m
    \e[90m  API base    :\e[0m \e[36m#{scheme}://#{host}:#{port}/api\e[0m
    \e[90m  Auth routes :\e[0m \e[36m/api/auth/validate-token, /verify-code, /resend-code\e[0m
    \e[90m  ─────────────────────────────────────────────\e[0m
    \e[2m  Logs kiye ja rahe hain...\e[0m
    \e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m
    """

    IO.puts(banner)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FirmtechApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
