defmodule FirmtechApi.UserStaffsTest do
  use FirmtechApi.DataCase

  alias FirmtechApi.UserStaffs

  describe "user_staffs" do
    alias FirmtechApi.UserStaffs.UserStaff

    import FirmtechApi.UserStaffsFixtures

    @invalid_attrs %{status: nil}

    test "list_user_staffs/0 returns all user_staffs" do
      user_staff = user_staff_fixture()
      assert UserStaffs.list_user_staffs() == [user_staff]
    end

    test "get_user_staff!/1 returns the user_staff with given id" do
      user_staff = user_staff_fixture()
      assert UserStaffs.get_user_staff!(user_staff.id) == user_staff
    end

    test "create_user_staff/1 with valid data creates a user_staff" do
      valid_attrs = %{status: 42}

      assert {:ok, %UserStaff{} = user_staff} = UserStaffs.create_user_staff(valid_attrs)
      assert user_staff.status == 42
    end

    test "create_user_staff/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UserStaffs.create_user_staff(@invalid_attrs)
    end

    test "update_user_staff/2 with valid data updates the user_staff" do
      user_staff = user_staff_fixture()
      update_attrs = %{status: 43}

      assert {:ok, %UserStaff{} = user_staff} = UserStaffs.update_user_staff(user_staff, update_attrs)
      assert user_staff.status == 43
    end

    test "update_user_staff/2 with invalid data returns error changeset" do
      user_staff = user_staff_fixture()
      assert {:error, %Ecto.Changeset{}} = UserStaffs.update_user_staff(user_staff, @invalid_attrs)
      assert user_staff == UserStaffs.get_user_staff!(user_staff.id)
    end

    test "delete_user_staff/1 deletes the user_staff" do
      user_staff = user_staff_fixture()
      assert {:ok, %UserStaff{}} = UserStaffs.delete_user_staff(user_staff)
      assert_raise Ecto.NoResultsError, fn -> UserStaffs.get_user_staff!(user_staff.id) end
    end

    test "change_user_staff/1 returns a user_staff changeset" do
      user_staff = user_staff_fixture()
      assert %Ecto.Changeset{} = UserStaffs.change_user_staff(user_staff)
    end
  end
end
