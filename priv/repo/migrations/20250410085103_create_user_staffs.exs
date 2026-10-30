defmodule FirmtechApi.Repo.Migrations.CreateUserStaffs do
  use Ecto.Migration

  def change do
    create table(:user_staffs) do
      add :user_id, references(:users, on_delete: :nothing, type: :uuid), null: false
      add :staff_id, references(:staffs, on_delete: :nothing), null: false
      add :status, :smallint

      timestamps(type: :utc_datetime)
    end

    create index(:user_staffs, [:user_id], name: :idx_user_staffs_user_id)
    create index(:user_staffs, [:staff_id], name: :idx_user_staffs_staff_id)

    # create unique index on user_id and staff_id
    create unique_index(:user_staffs, [:user_id, :staff_id],
             name: :unq_user_staffs_user_id_staff_id
           )
  end
end
