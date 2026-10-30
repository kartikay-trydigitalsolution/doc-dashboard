defmodule FirmtechApi.RecordResults.RecordResult do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :cluster,
             :start,
             :end,
             :global_best_score,
             :firmness,
             :erection_class,
             :time_4_to_6,
             :time_6_to_8,
             :time_8_to_10
           ]}

  @primary_key false
  schema "recordsResults" do
    field :cluster, :integer, primary_key: true
    field :start, :naive_datetime
    field :end, :naive_datetime
    field :global_best_score, :decimal
    field :firmness, :decimal

    field :erection_class, Ecto.Enum,
      values: [:SEX, :SOLO, :SLEEP, :UNKNOWN, :FALSE, :MORNING, :OTHER]

    # Relationships
    belongs_to :record, FirmtechApi.Records.Record,
      foreign_key: :record_sid,
      references: :sid,
      primary_key: true

    field :time_4_to_6, :integer
    field :time_6_to_8, :integer
    field :time_8_to_10, :integer

    # No timestamps as they're not in the DDL
  end

  @doc """
  Creates a record result changeset.
  """
  def changeset(record_result, attrs) do
    record_result
    |> cast(attrs, [
      :cluster,
      :record_sid,
      :start,
      :end,
      :global_best_score,
      :firmness,
      :erection_class,
      :time_4_to_6,
      :time_6_to_8,
      :time_8_to_10
    ])
    |> validate_required([:cluster, :record_sid])
    |> foreign_key_constraint(:record_sid)
  end
end
