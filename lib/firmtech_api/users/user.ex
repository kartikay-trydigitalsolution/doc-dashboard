defmodule FirmtechApi.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:id, :first_name, :last_name, :age],
    sortable: [:id, :first_name, :last_name],
    adapter_opts: [
      custom_fields: [
        age: [
          filter: {FirmtechApi.Users.CustomFilters, :age_filter, []},
          ecto_type: :integer,
          operators: [:==, :!=, :>, :<, :>=, :<=]
        ]
      ]
    ]
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :sub, :binary_id
    field :username, :string
    field :onboarded, :boolean, default: false
    field :status, Ecto.Enum, values: [:active, :deleted]
    field :date_of_birth, :date
    field :shim_score, :integer
    field :weight, :decimal
    field :weight_unit, Ecto.Enum, values: [:KG, :LB]
    field :height, :decimal
    field :height_unit, Ecto.Enum, values: [:CM, :IN]
    field :bmi, :decimal
    field :diabetes, :boolean
    field :diabetes_comments, :string
    field :hypertension, :boolean
    field :hypertension_comments, :string
    field :tobacco, :boolean
    field :tobacco_comments, :string
    field :alcohol, :boolean
    field :alcohol_comments, :string
    field :prescription_drugs, :boolean
    field :prescription_drugs_comments, :string
    field :recreational_drugs, :boolean
    field :recreational_drugs_comments, :string
    field :personal_comments, :string
    field :best_score, :decimal
    field :best_score_record_id, :binary_id
    field :best_score_record_started_at, :utc_datetime
    field :last_open_app_at, :date
    field :last_upload_at, :date
    field :last_upload_record_id, :binary_id
    field :last_upload_cluster_count, :integer
    field :statistics_uploads_count, :integer
    field :deleted_at, :naive_datetime
    field :last_upload_timestamp_at, :naive_datetime
    field :enrolled, :boolean, default: false
    field :uf_climax, :boolean
    field :res_id, :binary_id
    field :first_name, :string
    field :last_name, :string
    field :staff_notes, :string
    field :ed_diagnosis, :boolean
    field :ed_concern, :boolean
    field :latest_performance_data, :map, virtual: true
    field :efs, :decimal, virtual: true

    # Synced from DynamoDB via syncUsers
    field :language_code, :string, virtual: true
    field :notifications_enabled, :boolean, virtual: true
    field :push_token, :string, virtual: true
    field :relationship_status, :string, virtual: true
    field :relationship_orientation, :string, virtual: true
    field :activity_level, :string, virtual: true
    field :goals, {:array, :string}, virtual: true
    field :health_conditions, {:array, :string}, virtual: true
    field :medications_data, :map, virtual: true
    field :cannabis, :string, virtual: true
    field :sleep, :integer, virtual: true
    field :stress, :integer, virtual: true
    field :q1, :string, virtual: true
    field :q2, :string, virtual: true
    field :q3, :string, virtual: true
    field :q4, :string, virtual: true
    field :q5, :string, virtual: true
    field :q6, :string, virtual: true
    field :q7, :string, virtual: true
    field :q8, :string, virtual: true
    field :user_consent, :map, virtual: true

    # Fields present in PostgreSQL users table
    field :erection_hardness, :string
    field :erection_hardness_score, :integer
    field :ehs_score, :integer
    field :shim_severity, :string
    field :permanent_residency_country_code, :string
    field :performance_data, :map
    field :shim_q1_confidence, :integer
    field :shim_q2_penetration_hardness, :integer
    field :shim_q3_maintenance, :integer
    field :shim_q4_satisfaction, :integer
    field :shim_q5_difficulty, :integer
    # Relationships
    has_many :records, FirmtechApi.Records.Record, foreign_key: :userId
    has_many :performance_datas, FirmtechApi.PerformanceDatas.PerformanceData

    # Adding timestamps even though they're not in the DDL for best practices
    # timestamps()
  end

  @doc """
  Creates a user changeset.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      # :sub,
      # :username,
      # :onboarded,
      # :status,
      # :date_of_birth,
      # :shim_score,
      # :weight,
      # :weight_unit,
      # :height,
      # :height_unit,
      # :bmi,
      # :diabetes,
      # :diabetes_comments,
      # :hypertension,
      # :hypertension_comments,
      # :tobacco,
      # :tobacco_comments,
      # :alcohol,
      # :alcohol_comments,
      # :prescription_drugs,
      # :prescription_drugs_comments,
      # :recreational_drugs,
      # :recreational_drugs_comments,
      # :personal_comments,
      # :best_score,
      # :best_score_record_id,
      # :best_score_record_started_at,
      # :last_open_app_at,
      # :last_upload_at,
      # :last_upload_record_id,
      # :last_upload_cluster_count,
      # :statistics_uploads_count,
      # :deleted_at,
      # :last_upload_timestamp_at,
      # :enrolled,
      # :uf_climax,
      # :res_id,
      # :first_name,
      # :last_name,
      :staff_notes
    ])
    |> validate_required([:id])
  end
end
