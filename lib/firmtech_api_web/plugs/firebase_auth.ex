defmodule FirmtechApiWeb.Plugs.FirebaseAuth do
  import Plug.Conn

  # doctors schema ..
  alias FirmtechApi.Staffs
  alias FirmtechApi.Staffs.Staff

  alias ExFirebaseAuth.Token

  def init(default), do: default

  def call(conn, _opts) do
    # TODO: temp
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, _uid,
          %JOSE.JWT{
            fields: %{
              # "api_staff_id" => api_staff_id,
              "aud" => _audience,
              "auth_time" => _auth_time,
              "email" => email,
              "email_verified" => _email_verified,
              "exp" => _exp,
              "firebase" => %{
                "identities" => %{"email" => [_identity_email]},
                "sign_in_provider" => _sign_in_provider
              },
              "iat" => _iat,
              "iss" => _issuer,
              "sub" => _sub,
              "user_id" => user_id
            }
          } = jwt} <- Token.verify_token(token),

         #  Staffs.get_staff_by_id_and_firebase_uid!(api_staff_id, user_id) do
         %Staff{} =
           staff_user <-
           Staffs.get_staff_by_firebase_uid!(user_id) do
      IO.inspect("uid :#{user_id}")
      IO.inspect("email :#{email}")
      IO.inspect(jwt)

      conn
      |> assign(:api_staff_id, staff_user.id)
      |> assign(:current_staff, staff_user)

      # TODO: temp
      # conn
    else
      _ ->
        conn
        |> send_resp(:unauthorized, "Unauthorized")
        |> halt()
    end
  end
end

# user = ChefiUsers.get_or_create_user(%FirebaseData{firebase_uid: user_id, email: email})
# |> assign(:firebase_data, firebase_data)
