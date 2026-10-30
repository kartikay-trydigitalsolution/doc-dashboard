defmodule FirmtechApi.PerformanceDatas.PerformanceData do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [
    :updated_at, :erectile_fitness_score
  ]}

  # :avg_firmness_score, :avg_nocturnal_firmness_score,  :record_count, :avg_erections_per_week, :avg_duration, :total_erections, :solo_sex_count, :nocturnal_count, :avg_nocturnal_erections_per_week, :avg_nocturnal_erections, :avg_firmness_score__nocturnal, :avg_firmness_score__sex_solo, :avg_total_duration__nocturnal, :avg_total_duration__sex_solo, :avg_count__nocturnal, :avg_count__sex_solo, :duration_of_sex_solo_erections_in_seconds, :duration_of_sleep_erections_in_seconds, :performance_data_trigger, :user_id, :record_sid

  @primary_key false
  schema "performance_data" do
    field :updated_at, :naive_datetime, primary_key: true
    field :erectile_fitness_score, :decimal
    field :avg_firmness_score, :decimal
    field :avg_nocturnal_firmness_score, :decimal
    field :record_count, :integer
    field :avg_erections_per_week, :decimal
    field :avg_duration, :decimal
    field :total_erections, :integer
    field :solo_sex_count, :integer
    field :nocturnal_count, :integer
    field :avg_nocturnal_erections_per_week, :decimal
    field :avg_nocturnal_erections, :decimal
    field :avg_firmness_score__nocturnal, :decimal
    field :avg_firmness_score__sex_solo, :decimal
    field :avg_total_duration__nocturnal, :integer
    field :avg_total_duration__sex_solo, :integer
    field :avg_count__nocturnal, :decimal
    field :avg_count__sex_solo, :decimal
    field :duration_of_sex_solo_erections_in_seconds, :integer
    field :duration_of_sleep_erections_in_seconds, :integer

    field :performance_data_trigger, Ecto.Enum,
      values: [:post_insert_record, :refresh, :sync_record]

    # Relationships
    belongs_to :user, FirmtechApi.Users.User,
      foreign_key: :user_id,
      references: :id,
      type: :binary_id,
      primary_key: true

    belongs_to :record, FirmtechApi.Records.Record,
      foreign_key: :record_sid,
      references: :sid

    # No timestamps as they're not in the DDL
  end
end
