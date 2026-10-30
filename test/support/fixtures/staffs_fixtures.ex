defmodule FirmtechApi.StaffsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FirmtechApi.Staffs` context.
  """

  @doc """
  Generate a staff.
  """
  def staff_fixture(attrs \\ %{}) do
    {:ok, staff} =
      attrs
      |> Enum.into(%{
        category: 42,
        email: "some email",
        fb_meta: %{},
        fb_name: "some fb_name",
        fb_profile_picture: "some fb_profile_picture",
        firebase_uid: "some firebase_uid",
        first_name: "some first_name",
        last_name: "some last_name",
        status: 42
      })
      |> FirmtechApi.Staffs.create_staff()

    staff
  end
end
