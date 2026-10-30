defmodule FirmtechApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :sub, :uuid
      add :username, :string
      add :onboarded, :boolean, default: false
      add :status, :smallint
      add :date_of_birth, :date
      add :shim_score, :integer
      add :weight, :decimal
      add :weight_unit, :smallint
      add :height, :decimal
      add :height_unit, :smallint
      add :bmi, :decimal
      add :diabetes, :boolean
      add :diabetes_comments, :string
      add :hypertension, :boolean
      add :hypertension_comments, :string
      add :tobacco, :boolean
      add :tobacco_comments, :string
      add :alcohol, :boolean
      add :alcohol_comments, :string
      add :prescription_drugs, :boolean
      add :prescription_drugs_comments, :string
      add :recreational_drugs, :boolean
      add :recreational_drugs_comments, :string
      add :personal_comments, :string
      add :best_score, :decimal
      add :best_score_record_id, :uuid
      add :best_score_record_started_at, :utc_datetime
      add :last_open_app_at, :date
      add :last_upload_at, :date
      add :last_upload_record_id, :uuid
      add :last_upload_cluster_count, :integer
      add :statistics_uploads_count, :integer
      add :deleted_at, :naive_datetime
      add :last_upload_timestamp_at, :naive_datetime
      add :enrolled, :boolean, default: false
      add :uf_climax, :boolean
      add :res_id, :uuid
    end
  end
end