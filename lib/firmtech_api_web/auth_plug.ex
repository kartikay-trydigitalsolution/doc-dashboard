defmodule FirmtechApiWeb.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller
  require Logger

  alias FirmtechApi.Repo
  alias FirmtechApi.Staffs
  alias FirmtechApi.Staffs.Staff

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, firebase_uid, email} <- extract_credentials(token),
         staff when not is_nil(staff) <- resolve_staff(firebase_uid, email) do
      conn
      |> assign(:api_staff_id, staff.id)
      |> assign(:current_staff, staff)
    else
      error ->
        _ = IO.inspect(error, label: "Auth error")

        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})
        |> halt()
    end
  end

  defp extract_credentials(token) do
    case FirmtechApi.Token.verify_user_token(token) do
      {:ok, claims} ->
        firebase_uid = Map.get(claims, :firebase_uid) || Map.get(claims, "firebase_uid")
        email = Map.get(claims, :email) || Map.get(claims, "email")
        {:ok, firebase_uid, email}

      {:error, _} ->
        case ExFirebaseAuth.Token.verify_token(token) do
          {:ok, _uid, %JOSE.JWT{fields: fields}} ->
            firebase_uid = fields["user_id"] || fields["sub"]
            email = fields["email"]
            {:ok, firebase_uid, email}

          error ->
            error
        end
    end
  end

  defp resolve_staff(firebase_uid, email) do
    cond do
      is_binary(firebase_uid) and firebase_uid != "" ->
        case Staffs.get_staff_by_firebase_uid(firebase_uid) do
          %Staff{} = staff ->
            staff

          nil when is_binary(email) and email != "" ->
            find_and_link_staff_by_email(email, firebase_uid)

          _ ->
            nil
        end

      is_binary(email) and email != "" ->
        Repo.get_by(Staff, email: email)

      true ->
        nil
    end
  end

  defp find_and_link_staff_by_email(email, firebase_uid) do
    case Repo.get_by(Staff, email: email) do
      %Staff{} = staff ->
        case Staffs.update_staff(staff, %{firebase_uid: firebase_uid}) do
          {:ok, updated_staff} ->
            Logger.info("Linked staff #{staff.id} (#{email}) with firebase_uid #{firebase_uid}")
            updated_staff

          {:error, _changeset} ->
            staff
        end

      nil ->
        nil
    end
  end
end
