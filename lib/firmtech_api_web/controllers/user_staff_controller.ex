defmodule FirmtechApiWeb.UserStaffController do
  use FirmtechApiWeb, :controller

  alias FirmtechApi.UserStaffs
  alias FirmtechApi.UserStaffs.UserStaff

  action_fallback FirmtechApiWeb.FallbackController

  # def index(conn, _params) do
  #   user_staffs = UserStaffs.list_user_staffs()
  #   render(conn, :index, user_staffs: user_staffs)
  # end

  # def create(conn, %{"user_staff" => user_staff_params}) do
  #   with {:ok, %UserStaff{} = user_staff} <- UserStaffs.create_user_staff(user_staff_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", ~p"/api/user_staffs/#{user_staff}")
  #     |> render(:show, user_staff: user_staff)
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   user_staff = UserStaffs.get_user_staff!(id)
  #   render(conn, :show, user_staff: user_staff)
  # end

  # def update(conn, %{"id" => id, "user_staff" => user_staff_params}) do
  #   user_staff = UserStaffs.get_user_staff!(id)

  #   with {:ok, %UserStaff{} = user_staff} <- UserStaffs.update_user_staff(user_staff, user_staff_params) do
  #     render(conn, :show, user_staff: user_staff)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   user_staff = UserStaffs.get_user_staff!(id)

  #   with {:ok, %UserStaff{}} <- UserStaffs.delete_user_staff(user_staff) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
