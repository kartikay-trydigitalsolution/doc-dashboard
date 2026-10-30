defmodule FirmtechApi.Repo.Migrations.CreateRecords do
  use Ecto.Migration

  def change do
    create table(:records, primary_key: false) do
      add :sid, :bigserial, primary_key: true
      add :id, :uuid, null: false
      add :userId, references(:users, on_delete: :delete_all, type: :uuid), null: false
      add :started_at, :utc_datetime
      add :started_at_unix_timestamp, :integer
      add :timeZoneOffsetMinutes, :integer
      add :duration, :integer
      add :sex_count, :integer
      add :sex_rating, :integer
      add :recreational_drugs, :boolean
      add :slept, :boolean, default: false
      add :solo_count, :integer
      add :consumed_alcohol_units, :integer
      add :inserted_at_unix_timestamp, :integer
      add :score, :decimal
      add :fw_version, :integer
      add :app_version, :string
      add :preprocess_sql_inserted_at, :naive_datetime
      add :_replicated, :boolean
      add :clusters_marked_by_user, :integer
      add :deleted_at, :naive_datetime
      add :recording_area, :decimal
      add :personal_comments, :string
      add :prescription_drugs_array, {:array, :map}
    end

    create unique_index(:records, [:id], name: :records_id_idx)
    create index(:records, [:userId], name: :records_userid_idx)
  end
end