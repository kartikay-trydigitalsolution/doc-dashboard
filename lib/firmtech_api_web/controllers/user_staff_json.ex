defmodule FirmtechApiWeb.UserStaffJSON do
  alias FirmtechApi.UserStaffs.UserStaff

  @doc """
  Renders a list of user_staffs.
  """
  def index(%{user_staffs: user_staffs}) do
    %{data: for(user_staff <- user_staffs, do: data(user_staff))}
  end

  @doc """
  Renders a single user_staff.
  """
  def show(%{user_staff: user_staff}) do
    %{data: data(user_staff)}
  end

  defp data(%UserStaff{} = user_staff) do
    %{
      id: user_staff.id,
      status: user_staff.status
    }
  end
end
