defmodule FirmtechApiWeb.StaffJSON do
  alias FirmtechApi.Staffs.Staff
  alias FirmtechApi.UserStaffs.UserStaff

  @doc """
  Renders a list of staffs.
  """
  def index(%{staffs: staffs}) do
    %{data: for(staff <- staffs, do: data(staff))}
  end

  @doc """
  Renders a single staff.
  """
  def show(%{staff: staff}) do
    %{data: data(staff)}
  end

  @doc """
  Renders a newly created doctor, including the temporary password when the
  backend generated one (it is only available in this response).
  """
  def create(%{staff: staff, temporary_password: temporary_password} = assigns) do
    %{
      data:
        data(staff)
        |> Map.merge(%{
          firebase_uid: staff.firebase_uid,
          status: staff.status,
          category: staff.category,
          provider_id: assigns[:provider_id]
        }),
      temporary_password: temporary_password
    }
  end

  defp data(nil), do: nil

  defp data(%Staff{} = staff) do
    %{
      id: staff.id,
      first_name: staff.first_name,
      last_name: staff.last_name,
      email: staff.email,
      affiliation_code: staff.affiliation_code
    }
  end

  defp data(%UserStaff{} = user_staff) do
    %{
      id: user_staff.id,
      user_id: user_staff.user_id,
      staff_id: user_staff.staff_id,
      status: user_staff.status,
      staff: data(user_staff.staff)
    }
  end
end
