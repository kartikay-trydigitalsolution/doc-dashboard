defmodule FirmtechApi.Records.Record do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:userId, :started_at], sortable: [:started_at]
  }
  @derive {Jason.Encoder, only: [
    :sid, :id, :started_at, :started_at_unix_timestamp, :timeZoneOffsetMinutes, :duration,
    :sex_count, :sex_rating, :recreational_drugs, :slept, :solo_count, :consumed_alcohol_units,
    :inserted_at_unix_timestamp, :score, :fw_version, :app_version, :preprocess_sql_inserted_at,
    :_replicated, :clusters_marked_by_user, :deleted_at, :recording_area, :personal_comments,
    :prescription_drugs_array, :recording_statistics, :userId, :graph_img_url, :record_results
  ]}

  @primary_key {:sid, :id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "records" do
    field :id, :binary_id
    field :started_at, :utc_datetime
    field :started_at_unix_timestamp, :integer
    field :timeZoneOffsetMinutes, :integer
    field :duration, :integer
    field :sex_count, :integer
    field :sex_rating, :integer
    field :recreational_drugs, :boolean
    field :slept, :boolean, default: false
    field :solo_count, :integer
    field :consumed_alcohol_units, :integer
    field :inserted_at_unix_timestamp, :integer
    field :score, :decimal
    field :fw_version, :integer
    field :app_version, :string
    field :preprocess_sql_inserted_at, :naive_datetime
    field :_replicated, :boolean
    field :clusters_marked_by_user, :integer
    field :deleted_at, :naive_datetime
    field :recording_area, :decimal
    field :personal_comments, :string
    field :prescription_drugs_array, {:array, :map}
    field :recording_statistics, :map

    # Relationships
    belongs_to :user, FirmtechApi.Users.User,
      foreign_key: :userId,
      references: :id,
      type: :binary_id

    has_many :record_results, FirmtechApi.RecordResults.RecordResult, foreign_key: :record_sid
    # has_one :performance_data, FirmtechApi.Metrics.PerformanceData, foreign_key: :record_sid

    field :graph_img_url, :string, virtual: true

    # No timestamps as they're not in the DDL and we're using different timestamp tracking
  end

  @doc """
  Creates a record changeset.
  """
  def changeset(record, attrs) do
    record
    |> cast(attrs, [
      :id,
      :userId,
      :started_at,
      :started_at_unix_timestamp,
      :timeZoneOffsetMinutes,
      :duration,
      :sex_count,
      :sex_rating,
      :recreational_drugs,
      :slept,
      :solo_count,
      :consumed_alcohol_units,
      :inserted_at_unix_timestamp,
      :score,
      :fw_version,
      :app_version,
      :preprocess_sql_inserted_at,
      :_replicated,
      :clusters_marked_by_user,
      :deleted_at,
      :recording_area,
      :personal_comments,
      :prescription_drugs_array
    ])
    |> validate_required([:id, :userId])
    |> unique_constraint(:id, name: :records_id_idx)
    |> foreign_key_constraint(:userId)
  end
end
