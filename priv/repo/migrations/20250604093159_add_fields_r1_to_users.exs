defmodule FirmtechApi.Repo.Migrations.AddFieldsR1ToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ed_diagnosis, :boolean, null: true
      add :ed_concern, :boolean, null: true
    end
  end
end
