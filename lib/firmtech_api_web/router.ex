defmodule FirmtechApiWeb.Router do
  use FirmtechApiWeb, :router
  alias FirmtechApiWeb.Plugs.FirebaseAuth

  pipeline :api do
    plug :accepts, ["json"]
    # plug FirebaseAuth
    plug FirmtechApiWeb.AuthPlug
  end

  scope "/api", FirmtechApiWeb do
    pipe_through :api
  end

  pipeline :api_bypass_auth do
    plug :accepts, ["json"]
  end

  # <-- Add this line
  use Plug.ErrorHandler

  # and implement the callback handle_errors/2
  defp handle_errors(conn, %{reason: %Phoenix.Router.NoRouteError{message: message}}) do
    conn |> json(%{error: message}) |> halt()
  end

  defp handle_errors(conn, %{reason: {:error, reason}}) do
    # Pass through to fallback controller
    FirmtechApiWeb.FallbackController.call(conn, {:error, reason})
  end

  defp handle_errors(conn, _) do
    conn |> put_status(:internal_server_error) |> json(%{error: "Internal Server Error"}) |> halt()
  end

  # bypass auth for public endpoints
  scope "/api", FirmtechApiWeb do
    pipe_through :api_bypass_auth

    # Initial Firebase token validation
    post "/auth/validate-token", AuthController, :validate_firebase_token

    # Verification code endpoints
    post "/auth/verify-code", AuthController, :verify_code
    post "/auth/resend-code", AuthController, :resend_verification_code

    post "/staffs/affiliate", StaffController, :affiliate
    get "/staffs/my-doctor", StaffController, :my_doctor

    post "/staffs/me", StaffController, :get_or_create_staff

    # post "/callfluent_redirect", CallFluentRedirectController, :redirect_request

    # post "/chefi_users/me", ChefiUserController, :get_or_create_chefi_user
    # # todo: restict this only to Sanity only? use IP whitelist? or API key?
    # resources "/restaurants", RestaurantController, only: [:show, :index]

    # scope "/v1/ivr" do
    #   post "/process_recording", V1.IvrController, :process_recording
    # end

    # scope "/v1/callfluent" do
    #   post "/process", V1.CallfluentController, :process
    # end

    # post "/callfluent", CallFluentWebhookController, :handle_webhook
  end

  scope "/api", FirmtechApiWeb do
    pipe_through :api

    # TODO: verify this ..
    get "/staffs/my-details", StaffController, :my_details
    resources "/staffs", StaffController, except: [:new, :edit]

    # resources "/chefs", ChefController, except: [:new, :edit]

    # unaffiliate_by_staff
    post "/users/unaffiliate_by_staff/:id", UserController, :unaffiliate_by_staff

    get "/users/:id/statistics", UserController, :statistics
    get "/users/:id/range_data", UserController, :range_data
    get "/users/:id/export", UserController, :export

    # User routes
    resources "/users", UserController, except: [:create, :new, :edit] do
      get "/profile", UserController, :profile
      get "/risk_factors", UserController, :risk_factors
      get "/progress", UserController, :progress
      post "/calculate_bmi", UserController, :calculate_bmi
    end

    # Record routes
    resources "/records", RecordController, except: [:new, :edit] do
      resources "/results", RecordResultController,
        only: [:index, :show, :create, :update, :delete],
        param: "cluster"
    end

    # Performance data routes
    get "/performance_data/latest", PerformanceDataController, :latest

    resources "/performance_data", PerformanceDataController,
      only: [:index, :show, :create, :update],
      param: "updated_at"

    # Custom analytics routes
    scope "/analytics" do
      get "/overview/:user_id", AnalyticsController, :overview
      get "/trends/:user_id", AnalyticsController, :trends
      get "/comparisons/:user_id", AnalyticsController, :comparisons
    end

    # scope "/chefs" do
    #   # get "/list", ChefController, :list
    #   post "/claim", ChefController, :claim
    # end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:firmtech_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: FirmtechApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
