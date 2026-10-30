defmodule FirmtechApiWeb.StaffController do
  use FirmtechApiWeb, :controller

  alias FirmtechApi.Staffs
  alias FirmtechApi.Staffs.Staff
  alias ExFirebaseAuth.Token

  alias FirmtechApi.Staffs.FirebaseData

  action_fallback FirmtechApiWeb.FallbackController

  def index(conn, _params) do
    staffs = Staffs.list_staffs()
    render(conn, :index, staffs: staffs)
  end

  # [POST] /api/staffs/me
  def get_or_create_staff(conn, %{"staff" => staff_params} = params) do
    IO.inspect(params)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, _uid,
          %JOSE.JWT{
            fields: _fields
          } = fb_user_data} <- Token.verify_token(token) do
      IO.inspect(fb_user_data)

      fb_data = %FirebaseData{
        firebase_uid: fb_user_data.fields["user_id"],
        email: fb_user_data.fields["email"],
        fb_name: fb_user_data.fields["name"] || nil,
        fb_profile_picture: fb_user_data.fields["picture"] || nil,
        fb_meta: fb_user_data.fields["firebase"] || nil
      }

      # if staff_params has full_name, read it and set it to fb_data
      # fb_data =
      #   if staff_params["fullName"] do
      #     %{fb_data | fb_name: staff_params["fullName"]}
      #   else
      #     fb_data
      #   end

      # fb_data =
      #   if staff_params["email"] do
      #     %{fb_data | email: staff_params["email"]}
      #   else
      #     fb_data
      #   end

      IO.puts("fb_data")
      IO.inspect(fb_data)

      staff =
        Staffs.get_or_create_staff(fb_data, %{
          first_name: staff_params["first_name"],
          last_name: staff_params["last_name"]
        })

      IO.inspect(staff)

      conn =
        conn
        |> assign(:api_staff_id, staff.id)
        |> put_status(if staff.is_new == true, do: :created, else: :ok)

      render(conn, :show, staff: staff)
    else
      _ ->
        conn
        |> send_resp(:unauthorized, "Unauthorized")
        |> halt()
    end
  end

  @doc """
  POST /api/staffs (admin only)

  Adds a doctor: creates the Firebase Auth user (email + password) and the
  `staffs` row with a unique `affiliation_code`, which is the code the patient
  types in the app to link with this doctor.

  Body: `{"email": ..., "first_name": ..., "last_name": ..., "category": "doctor",
  "password": ..., "affiliation_code": ...}`. When `password` is not given, a
  temporary one is generated and returned once in the response.
  """
  def create(conn, _params) do
    staff_params = create_params(conn)

    with :ok <- authorize_admin(conn),
         {:ok, staff, temporary_password, provider_id} <-
           Staffs.create_doctor(%{
             email: staff_params["email"],
             first_name: staff_params["first_name"],
             last_name: staff_params["last_name"],
             full_name: staff_params["full_name"],
             category: parse_category(staff_params["category"]),
             password: staff_params["password"],
             affiliation_code: staff_params["affiliation_code"],
             provider_category: staff_params["provider_category"],
             qualifications: staff_params["qualifications"],
             clinic_name: staff_params["clinic_name"],
             website_url: staff_params["website_url"],
             address: staff_params["address"],
             city: staff_params["city"],
             state: staff_params["state"],
             services: parse_services(staff_params["services"]),
             schedule_url: staff_params["schedule_url"],
             telehealth_available: parse_boolean(staff_params["telehealth_available"]),
             phone: staff_params["phone"],
             profile_img: staff_params["profile_img"]
           }) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/staffs/#{staff.id}")
      |> render(:create,
        staff: staff,
        temporary_password: temporary_password,
        provider_id: provider_id
      )
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Forbidden"}) |> halt()

      {:error, :invalid_category} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid category"})
        |> halt()

      {:error, :invalid_provider_category} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error:
            "Invalid provider_category, expected one of: " <>
              Enum.join(FirmtechApi.ProviderCatalog.category_values(), ", ")
        })
        |> halt()

      {:error, :email_required} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "email is required"}) |> halt()

      {:error, :provider_table_not_configured} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "PROVIDER_TABLE_NAME is not configured"})
        |> halt()

      {:error, {:affiliation_code_conflict, email}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "affiliation_code already belongs to #{email}"})
        |> halt()

      {:error, {:provider_sync_failed, reason}} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{
          error: "Could not write the doctor to the provider catalog: #{inspect(reason)}"
        })
        |> halt()

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: changeset_message(changeset)})
        |> halt()

      {:error, {:firebase_error, status_code, message}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Firebase error (#{status_code}): #{message}"})
        |> halt()

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
        |> halt()
    end
  end

  defp create_params(conn) do
    case conn.body_params do
      %{"staff" => nested} when is_map(nested) -> nested
      body -> body
    end
  end

  defp authorize_admin(conn) do
    case conn.assigns.current_staff.category do
      category when category in [:admin, :manager] -> :ok
      _ -> {:error, :forbidden}
    end
  end

  defp parse_category(nil), do: :doctor
  defp parse_category(""), do: :doctor
  defp parse_category("admin"), do: :admin
  defp parse_category("manager"), do: :manager
  defp parse_category("doctor"), do: :doctor
  defp parse_category(:admin), do: :admin
  defp parse_category(:manager), do: :manager
  defp parse_category(:doctor), do: :doctor
  defp parse_category(_), do: :invalid

  defp parse_services(nil), do: nil

  defp parse_services(services) when is_list(services) do
    services
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_services(services) when is_binary(services) do
    services
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> nil
      list -> list
    end
  end

  defp parse_services(_services), do: nil

  defp parse_boolean(nil), do: nil
  defp parse_boolean(""), do: nil
  defp parse_boolean(true), do: true
  defp parse_boolean(false), do: false
  defp parse_boolean(value) when value in ["true", "1", "yes", "on"], do: true
  defp parse_boolean(value) when value in ["false", "0", "no", "off"], do: false
  defp parse_boolean(_value), do: nil

  defp changeset_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, messages} -> "#{field} #{Enum.join(messages, ", ")}" end)
    |> Enum.join("; ")
  end

  def show(conn, %{"id" => id}) do
    staff = Staffs.get_staff!(id)
    render(conn, :show, staff: staff)
  end

  # def update(conn, %{"id" => id, "staff" => staff_params}) do
  #   staff = Staffs.get_staff!(id)

  #   with {:ok, %Staff{} = staff} <- Staffs.update_staff(staff, staff_params) do
  #     render(conn, :show, staff: staff)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   staff = Staffs.get_staff!(id)

  #   with {:ok, %Staff{}} <- Staffs.delete_staff(staff) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end

  @spec my_doctor(Plug.Conn.t(), any()) :: nil | Plug.Conn.t()
  def my_doctor(conn, _params) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{"custom:uid" => aws_user_uid}} <- FirmtechApi.Aws.AwsActions.authenticate(token) do
      staff = Staffs.get_user_staff_by_aws_user_uid(aws_user_uid)

      IO.inspect(staff)

      render(conn, :show, staff: staff)
    else
      _ ->
        send_resp(conn, :unauthorized, "Unauthorized")
    end
  end

  @spec affiliate(Plug.Conn.t(), map()) ::
          [binary()]
          | {:error, :unauthorized}
          | {:ok, %{optional(binary()) => any()}}
          | Plug.Conn.t()
  def affiliate(conn, %{"affiliation_code" => affiliation_code, "action" => action}) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{"custom:uid" => aws_user_uid}} <- FirmtechApi.Aws.AwsActions.authenticate(token),
         {:ok, :affiliated_successfully} <-
           Staffs.affiliate(%{
             affiliation_code: affiliation_code,
             aws_user_uid: aws_user_uid,
             action: action
           }) do
      # render 200
      send_resp(conn, :ok, "OK")
    else
      {:error, "Staff not found"} ->
        send_resp(conn, :not_found, "Staff not found")

      _ ->
        send_resp(conn, :unauthorized, "Unauthorized")
    end
  end

  @spec my_details(Plug.Conn.t(), any()) :: nil | Plug.Conn.t()
  def my_details(conn, _params) do
    staff = conn.assigns.current_staff

    IO.inspect(staff)

    render(conn, :show, staff: staff)
  end
end
