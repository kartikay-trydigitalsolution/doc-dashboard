defmodule FirmtechApi.Repo.Migrations.AddAffiliationCodeToStaffs do
  use Ecto.Migration

  def change do
    alter table(:staffs) do
      add :affiliation_code, :string
    end

    create unique_index(:staffs, [:affiliation_code], name: "unq_staffs_affiliation_code")
  end
end
