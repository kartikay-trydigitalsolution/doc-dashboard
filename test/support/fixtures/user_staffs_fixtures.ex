defmodule FirmtechApi.UserStaffsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FirmtechApi.UserStaffs` context.
  """

  @doc """
  Generate a user_staff.
  """
  def user_staff_fixture(attrs \\ %{}) do
    {:ok, user_staff} =
      attrs
      |> Enum.into(%{
        status: 42
      })
      |> FirmtechApi.UserStaffs.create_user_staff()

    user_staff
  end
end
