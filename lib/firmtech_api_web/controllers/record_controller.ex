defmodule FirmtechApiWeb.RecordController do
  use FirmtechApiWeb, :controller

  alias FirmtechApi.Records
  alias FirmtechApi.Records.Record
  alias ExFirebaseAuth.Token

  action_fallback FirmtechApiWeb.FallbackController

  @spec index(Plug.Conn.t(), %{
          optional(:__struct__) => Flop,
          optional(atom() | binary()) => any()
        }) :: Plug.Conn.t()
  def index(conn, %{"userId" => _userId} = params) do
    IO.inspect(params, label: "params")
    current_staff = conn.assigns.current_staff

    case Records.list_by_user(params, current_staff) do
      {:ok, {records, meta}} ->
        render(conn, :index, meta: meta, records: records)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # def create(conn, %{"staff" => staff_params}) do
  #   with {:ok, %Staff{} = staff} <- Staffs.create_staff(staff_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", ~p"/api/staffs/#{staff}")
  #     |> render(:show, staff: staff)
  #   end
  # end

  def show(conn, %{"id" => id}) do
    record = Records.get_by_uuid_and_staff(id, conn.assigns.current_staff)
    render(conn, :show, record: record)
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
end
