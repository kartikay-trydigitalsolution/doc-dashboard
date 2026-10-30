defmodule FirmtechApi.Repo.Migrations.CreateVerificationCodes do
  use Ecto.Migration

  def change do
    create table(:verification_codes) do
      add :firebase_uid, :string, null: false
      add :code, :string, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:verification_codes, [:firebase_uid])
  end
end
