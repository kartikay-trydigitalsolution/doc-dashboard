defmodule FirmtechApi.Repo.Migrations.AddRecordingStatisticsToRecords do
  use Ecto.Migration

  def change do
    alter table(:records) do
      add :recording_statistics, :map, default: %{}
    end
  end
end
