defmodule FirmtechApiWeb.StaffControllerTest do
  use FirmtechApiWeb.ConnCase

  import FirmtechApi.StaffsFixtures

  alias FirmtechApi.Staffs.Staff

  @create_attrs %{
    status: 42,
    category: 42,
    firebase_uid: "some firebase_uid",
    first_name: "some first_name",
    last_name: "some last_name",
    email: "some email",
    fb_name: "some fb_name",
    fb_profile_picture: "some fb_profile_picture",
    fb_meta: %{}
  }
  @update_attrs %{
    status: 43,
    category: 43,
    firebase_uid: "some updated firebase_uid",
    first_name: "some updated first_name",
    last_name: "some updated last_name",
    email: "some updated email",
    fb_name: "some updated fb_name",
    fb_profile_picture: "some updated fb_profile_picture",
    fb_meta: %{}
  }
  @invalid_attrs %{status: nil, category: nil, firebase_uid: nil, first_name: nil, last_name: nil, email: nil, fb_name: nil, fb_profile_picture: nil, fb_meta: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all staffs", %{conn: conn} do
      conn = get(conn, ~p"/api/staffs")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create staff" do
    test "renders staff when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/staffs", staff: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/staffs/#{id}")

      assert %{
               "id" => ^id,
               "category" => 42,
               "email" => "some email",
               "fb_meta" => %{},
               "fb_name" => "some fb_name",
               "fb_profile_picture" => "some fb_profile_picture",
               "firebase_uid" => "some firebase_uid",
               "first_name" => "some first_name",
               "last_name" => "some last_name",
               "status" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/staffs", staff: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update staff" do
    setup [:create_staff]

    test "renders staff when data is valid", %{conn: conn, staff: %Staff{id: id} = staff} do
      conn = put(conn, ~p"/api/staffs/#{staff}", staff: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/staffs/#{id}")

      assert %{
               "id" => ^id,
               "category" => 43,
               "email" => "some updated email",
               "fb_meta" => %{},
               "fb_name" => "some updated fb_name",
               "fb_profile_picture" => "some updated fb_profile_picture",
               "firebase_uid" => "some updated firebase_uid",
               "first_name" => "some updated first_name",
               "last_name" => "some updated last_name",
               "status" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, staff: staff} do
      conn = put(conn, ~p"/api/staffs/#{staff}", staff: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete staff" do
    setup [:create_staff]

    test "deletes chosen staff", %{conn: conn, staff: staff} do
      conn = delete(conn, ~p"/api/staffs/#{staff}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/staffs/#{staff}")
      end
    end
  end

  defp create_staff(_) do
    staff = staff_fixture()
    %{staff: staff}
  end
end
