defmodule FirmtechApi.UserStaffs.UserStaff do
  use Ecto.Schema
  import Ecto.Changeset

  alias FirmtechApi.Users.User
  alias FirmtechApi.Staffs.Staff

  @derive {Jason.Encoder,
           only: [
             :id,
             :status,
             :user_id,
             :staff_id
           ]}

  schema "user_staffs" do
    belongs_to :user, User, type: :binary_id
    belongs_to :staff, Staff
    field :status, UserStaffStatusEnum, default: :affiliated
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_staff, attrs) do
    user_staff
    |> cast(attrs, [:status, :user_id, :staff_id])
    |> validate_required([:user_id, :staff_id])
  end
end
