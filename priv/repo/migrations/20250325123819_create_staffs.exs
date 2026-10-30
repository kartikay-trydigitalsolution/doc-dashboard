defmodule FirmtechApi.Repo.Migrations.CreateStaffs do
  use Ecto.Migration

  def change do
    create table(:staffs) do
      add :firebase_uid, :string, null: false
      add :category, StaffCategoryEnum.type(), null: true
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :status, StaffStatusEnum.type(), null: true
      add :fb_name, :string, size: 255
      add :fb_profile_picture, :string, size: 16384
      add :fb_meta, :jsonb

      timestamps(type: :utc_datetime)
    end

    create unique_index(:staffs, [:firebase_uid], name: "uni_staffs_firebase_uid")
  end
end
