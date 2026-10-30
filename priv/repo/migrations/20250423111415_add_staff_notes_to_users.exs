defmodule FirmtechApi.Repo.Migrations.AddStaffNotesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :staff_notes, :string
    end
  end
end
