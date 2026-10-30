defmodule FirmtechApi.PerformanceDatas do
  alias FirmtechApi.Repo
  alias FirmtechApi.PerformanceDatas.PerformanceData
  import Ecto.Query, warn: false

  @doc """
  Gets the latest performance data for a user.
  """
  def get_latest_for_user(user_id) do
    PerformanceData
    |> where([pd], pd.user_id == ^user_id)
    |> order_by([pd], desc: pd.updated_at)
    |> limit(1)
    |> Repo.one()
  end

  @serialize_fields [
    :updated_at,
    :erectile_fitness_score,
    :avg_firmness_score,
    :avg_nocturnal_firmness_score,
    :record_count,
    :avg_erections_per_week,
    :avg_duration,
    :total_erections,
    :solo_sex_count,
    :nocturnal_count,
    :avg_nocturnal_erections_per_week,
    :avg_nocturnal_erections,
    :avg_firmness_score__nocturnal,
    :avg_firmness_score__sex_solo,
    :avg_total_duration__nocturnal,
    :avg_total_duration__sex_solo,
    :avg_count__nocturnal,
    :avg_count__sex_solo,
    :duration_of_sex_solo_erections_in_seconds,
    :duration_of_sleep_erections_in_seconds
  ]

  @doc """
  JSON-safe map of the latest performance data row for a user, or nil.
  """
  def latest_map_for_user(user_id) do
    user_id
    |> get_latest_for_user()
    |> to_map()
  end

  @doc """
  Converts a PerformanceData struct into a JSON-safe map with string keys.
  """
  def to_map(nil), do: nil

  def to_map(%PerformanceData{} = pd) do
    Map.new(@serialize_fields, fn field ->
      {to_string(field), serialize_value(Map.get(pd, field))}
    end)
  end

  defp serialize_value(%Decimal{} = value), do: Decimal.to_float(value)
  defp serialize_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp serialize_value(value), do: value

  @doc """
  Gets a specific performance data entry.
  """
  def get!(user_id, updated_at) do
    Repo.get_by!(PerformanceData, user_id: user_id, updated_at: updated_at)
  end

  @doc """
  Gets a specific performance data entry.
  Returns `nil` if the Performance Data does not exist.
  """
  def get(user_id, updated_at) do
    Repo.get_by(PerformanceData, user_id: user_id, updated_at: updated_at)
  end

  @doc """
  Lists all performance data entries for a user.
  """
  def list_by_user(user_id) do
    PerformanceData
    |> where([pd], pd.user_id == ^user_id)
    |> order_by([pd], desc: pd.updated_at)
    |> Repo.all()
  end

  @doc """
  Creates a performance data entry.
  """
  def create(attrs \\ %{}) do
    %PerformanceData{}
    |> PerformanceData.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a performance data entry.
  """
  def update(%PerformanceData{} = performance_data, attrs) do
    performance_data
    |> PerformanceData.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a performance data entry from the database.
  """
  def delete(%PerformanceData{} = performance_data) do
    Repo.delete(performance_data)
  end

  @doc """
  Gets performance data related to a specific record.
  """
  def get_by_record(record_sid) do
    PerformanceData
    |> where([pd], pd.record_sid == ^record_sid)
    |> Repo.one()
  end

  @doc """
  Calculates average performance metrics across all users.
  """
  def calculate_average_metrics do
    PerformanceData
    |> select([pd], %{
      avg_erectile_fitness_score: avg(pd.erectile_fitness_score),
      avg_firmness_score: avg(pd.avg_firmness_score),
      avg_nocturnal_firmness_score: avg(pd.avg_nocturnal_firmness_score)
    })
    |> Repo.one()
  end
end
