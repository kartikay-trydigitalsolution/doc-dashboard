defmodule FirmtechApi.StaffsTest do
  use FirmtechApi.DataCase

  alias FirmtechApi.Staffs

  describe "staffs" do
    alias FirmtechApi.Staffs.Staff

    import FirmtechApi.StaffsFixtures

    @invalid_attrs %{status: nil, category: nil, firebase_uid: nil, first_name: nil, last_name: nil, email: nil, fb_name: nil, fb_profile_picture: nil, fb_meta: nil}

    test "list_staffs/0 returns all staffs" do
      staff = staff_fixture()
      assert Staffs.list_staffs() == [staff]
    end

    test "get_staff!/1 returns the staff with given id" do
      staff = staff_fixture()
      assert Staffs.get_staff!(staff.id) == staff
    end

    test "create_staff/1 with valid data creates a staff" do
      valid_attrs = %{status: 42, category: 42, firebase_uid: "some firebase_uid", first_name: "some first_name", last_name: "some last_name", email: "some email", fb_name: "some fb_name", fb_profile_picture: "some fb_profile_picture", fb_meta: %{}}

      assert {:ok, %Staff{} = staff} = Staffs.create_staff(valid_attrs)
      assert staff.status == 42
      assert staff.category == 42
      assert staff.firebase_uid == "some firebase_uid"
      assert staff.first_name == "some first_name"
      assert staff.last_name == "some last_name"
      assert staff.email == "some email"
      assert staff.fb_name == "some fb_name"
      assert staff.fb_profile_picture == "some fb_profile_picture"
      assert staff.fb_meta == %{}
    end

    test "create_staff/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Staffs.create_staff(@invalid_attrs)
    end

    test "update_staff/2 with valid data updates the staff" do
      staff = staff_fixture()
      update_attrs = %{status: 43, category: 43, firebase_uid: "some updated firebase_uid", first_name: "some updated first_name", last_name: "some updated last_name", email: "some updated email", fb_name: "some updated fb_name", fb_profile_picture: "some updated fb_profile_picture", fb_meta: %{}}

      assert {:ok, %Staff{} = staff} = Staffs.update_staff(staff, update_attrs)
      assert staff.status == 43
      assert staff.category == 43
      assert staff.firebase_uid == "some updated firebase_uid"
      assert staff.first_name == "some updated first_name"
      assert staff.last_name == "some updated last_name"
      assert staff.email == "some updated email"
      assert staff.fb_name == "some updated fb_name"
      assert staff.fb_profile_picture == "some updated fb_profile_picture"
      assert staff.fb_meta == %{}
    end

    test "update_staff/2 with invalid data returns error changeset" do
      staff = staff_fixture()
      assert {:error, %Ecto.Changeset{}} = Staffs.update_staff(staff, @invalid_attrs)
      assert staff == Staffs.get_staff!(staff.id)
    end

    test "delete_staff/1 deletes the staff" do
      staff = staff_fixture()
      assert {:ok, %Staff{}} = Staffs.delete_staff(staff)
      assert_raise Ecto.NoResultsError, fn -> Staffs.get_staff!(staff.id) end
    end

    test "change_staff/1 returns a staff changeset" do
      staff = staff_fixture()
      assert %Ecto.Changeset{} = Staffs.change_staff(staff)
    end
  end
end
