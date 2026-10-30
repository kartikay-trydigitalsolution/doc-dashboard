defmodule FirmtechApiWeb.AuthController do
  use FirmtechApiWeb, :controller

  alias FirmtechApi.VerificationCodes
  alias FirmtechApi.Staffs

  @doc """
  This endpoint handles the initial Firebase token validation.
  Instead of creating a session immediately, it generates a verification code
  and sends it to the user's email.
  """
  def validate_firebase_token(conn, %{"token" => token}) do
    with {:ok, firebase_uid,
          %JOSE.JWT{
            fields: claims
          } = _fb_user_data} <- ExFirebaseAuth.Token.verify_token(token),
         firebase_uid = claims["sub"],
         email = claims["email"],
         _user <- Staffs.get_staff_by_firebase_uid!(firebase_uid) do
      # Generate and send verification code
      IO.inspect(firebase_uid)
      IO.inspect(email)
      VerificationCodes.generate_for_user(firebase_uid, email)

      # Return temporary auth state that requires verification
      conn
      |> put_status(:ok)
      |> json(%{
        status: "verification_required",
        firebase_uid: firebase_uid,
        message: "Verification code sent to your email"
      })
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid token: #{reason}"})
    end
  end

  @doc """
  This endpoint handles the verification code submission.
  If the code is valid, it creates a session and returns a proper auth token.
  """
  def verify_code(conn, %{"firebase_uid" => firebase_uid, "code" => code}) do
    case VerificationCodes.verify_code(firebase_uid, code) do
      :ok ->
        case Staffs.get_staff_by_firebase_uid(firebase_uid) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "User not found. Please register first."})

          user ->
            # Code is valid, create a proper session
            token = FirmtechApi.Token.generate_user_token(user)

            conn
            |> put_status(:ok)
            |> json(%{
              status: "success",
              token: token,
              user: %{
                id: user.id,
                email: user.email
              }
            })
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "No verification pending"})

      {:error, :expired} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Verification code expired"})

      {:error, :invalid_code} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid verification code"})
    end
  end

  @doc """
  Endpoint to resend verification code if needed
  """
  def resend_verification_code(conn, %{"token" => token}) do
    with {:ok, firebase_uid,
          %JOSE.JWT{
            fields: claims
          } = _fb_user_data} <- ExFirebaseAuth.Token.verify_token(token),
         email = claims["email"] do
      VerificationCodes.generate_for_user(firebase_uid, email)

      conn
      |> put_status(:ok)
      |> json(%{
        status: "success",
        message: "Verification code resent"
      })
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid request: #{reason}"})
    end
  end
end
