defmodule FirmtechApi.RecordResults do
  alias FirmtechApi.RecordResults.RecordResult

  alias FirmtechApi.Repo

  import Ecto.Query, warn: false

  @doc """
  Gets a record result by its composite primary key.
  """
  def get!(record_sid, cluster) do
    Repo.get_by!(RecordResult, record_sid: record_sid, cluster: cluster)
  end

  @doc """
  Gets a record result by its composite primary key.
  Returns `nil` if the Record Result does not exist.
  """
  def get(record_sid, cluster) do
    Repo.get_by(RecordResult, record_sid: record_sid, cluster: cluster)
  end

  @doc """
  Lists all results for a specific record.
  """
  def list_by_record(record_sid) do
    RecordResult
    |> where([rr], rr.record_sid == ^record_sid)
    |> order_by([rr], asc: rr.cluster)
    |> Repo.all()
  end

  @doc """
  Creates a record result.
  """
  def create(attrs \\ %{}) do
    %RecordResult{}
    |> RecordResult.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a record result.
  """
  def update(%RecordResult{} = record_result, attrs) do
    record_result
    |> RecordResult.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a record result from the database.
  """
  def delete(%RecordResult{} = record_result) do
    Repo.delete(record_result)
  end

  @doc """
  Gets results by erection class.
  """
  def list_by_erection_class(record_sid, erection_class) do
    RecordResult
    |> where([rr], rr.record_sid == ^record_sid and rr.erection_class == ^erection_class)
    |> order_by([rr], asc: rr.cluster)
    |> Repo.all()
  end

  @doc """
  Gets results with highest firmness for a record.
  """
  def get_highest_firmness(record_sid) do
    RecordResult
    |> where([rr], rr.record_sid == ^record_sid)
    |> order_by([rr], desc: rr.firmness)
    |> limit(1)
    |> Repo.one()
  end
end
