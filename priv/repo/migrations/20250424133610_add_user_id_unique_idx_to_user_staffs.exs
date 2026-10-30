defmodule FirmtechApi.Repo.Migrations.AddUserIdUniqueIdxToUserStaffs do
  use Ecto.Migration

  def change do
    create unique_index(:user_staffs, [:user_id], name: "unq_user_staffs_user_id")
  end
end
