defmodule FirmtechApiWeb.UserStaffControllerTest do
  use FirmtechApiWeb.ConnCase

  import FirmtechApi.UserStaffsFixtures

  alias FirmtechApi.UserStaffs.UserStaff

  @create_attrs %{
    status: 42
  }
  @update_attrs %{
    status: 43
  }
  @invalid_attrs %{status: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all user_staffs", %{conn: conn} do
      conn = get(conn, ~p"/api/user_staffs")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create user_staff" do
    test "renders user_staff when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/user_staffs", user_staff: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/user_staffs/#{id}")

      assert %{
               "id" => ^id,
               "status" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/user_staffs", user_staff: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user_staff" do
    setup [:create_user_staff]

    test "renders user_staff when data is valid", %{conn: conn, user_staff: %UserStaff{id: id} = user_staff} do
      conn = put(conn, ~p"/api/user_staffs/#{user_staff}", user_staff: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/user_staffs/#{id}")

      assert %{
               "id" => ^id,
               "status" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user_staff: user_staff} do
      conn = put(conn, ~p"/api/user_staffs/#{user_staff}", user_staff: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user_staff" do
    setup [:create_user_staff]

    test "deletes chosen user_staff", %{conn: conn, user_staff: user_staff} do
      conn = delete(conn, ~p"/api/user_staffs/#{user_staff}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/user_staffs/#{user_staff}")
      end
    end
  end

  defp create_user_staff(_) do
    user_staff = user_staff_fixture()
    %{user_staff: user_staff}
  end
end
