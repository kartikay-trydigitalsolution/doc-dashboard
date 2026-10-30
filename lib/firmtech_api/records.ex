defmodule FirmtechApi.Records do
  alias FirmtechApi.Repo
  alias FirmtechApi.Records.Record
  alias FirmtechApi.Records.DynamoSync
  alias FirmtechApi.Users
  alias FirmtechApi.Staffs.Staff
  alias FirmtechApi.UserStaffs.UserStaff
  import Ecto.Query, warn: false
  alias FirmtechApi.Aws.S3Actions

  defp scope_this_staff(query, %Staff{id: staff_id}) do
    # where there is a UserStaff with staff_id and the User
    # where the UserStaff is approved
    query
    |> join(:inner, [r], u in FirmtechApi.Users.User, on: r.userId == u.id)
    |> join(:inner, [r, u], us in UserStaff, on: u.id == us.user_id)
    |> where([r, u, us], us.staff_id == ^staff_id)
    |> where([r, u, us], us.status == :affiliated)
  end

  @doc """
  Gets a record by its UUID (id field), not the primary key (sid).
  """
  def get_by_uuid_and_staff(uuid, current_staff) do
    # validate first that the record belongs to the staff, the record has a userId field
    Record
    |> scope_this_staff(current_staff)
    |> where([r], r.id == ^uuid)
    |> Repo.one()
  end

  @doc """
  Gets a record by its primary key (sid).
  """
  def get!(sid), do: Repo.get!(Record, sid)

  @doc """
  Gets a record by its primary key (sid).
  Returns `nil` if the Record does not exist.
  """
  def get(sid), do: Repo.get(Record, sid)

  @doc """
  Lists all records for a specific user.
  """

  @spec list_by_user(map) ::
          {:ok, {[Record.t()], Flop.Meta.t()}} | {:error, Flop.Meta.t()}

  def list_by_user(params \\ %{}, current_staff) do
    # check scope of user_id
    user_id = params["userId"]

    if Users.has_access?(user_id, current_staff) do
      # Synchronize records from DynamoDB to PostgreSQL
      DynamoSync.sync_user_records(user_id)

      {:ok, {records, meta}} =
        Record
        |> where([r], is_nil(r.deleted_at))
        |> where([r], r.userId == ^user_id)
        # order by started_at descending
        |> order_by([r], desc: r.started_at)
        |> preload([:record_results])
        |> Flop.validate_and_run(params, for: Record)

      # get presigned urls for images of records ..
      # for each record, get the presigned url for the image
      records =
        Enum.map(records, fn record ->
          s3_bucket =
            System.get_env("AWS_IMAGES_BUCKET") ||
              System.get_env("READINGS_BUCKET_NAME") ||
              "amplify-firmtechbackendge-readingsstoragebucketbd5-nlt2picud0lk"

          s3_key = "private/#{record.userId}/postprocess/#{record.id}.graph.png"

          record
          |> Map.put(:graph_img_url, S3Actions.get_presigned_url(s3_bucket, s3_key))
        end)

      {:ok, {records, meta}}
    else
      {:error, :forbidden}
    end
  end

  @doc """
  Creates a record.
  """
  def create(attrs \\ %{}) do
    %Record{}
    |> Record.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a record.
  """
  def update(%Record{} = record, attrs) do
    record
    |> Record.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft deletes a record by setting deleted_at timestamp.
  """
  def soft_delete(%Record{} = record) do
    record
    |> Record.changeset(%{deleted_at: NaiveDateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Hard deletes a record from the database.
  """
  def delete(%Record{} = record) do
    Repo.delete(record)
  end

  @doc """
  Gets records with their results and preload user.
  """
  def get_with_results(sid) do
    Record
    |> where([r], r.sid == ^sid)
    |> preload([:results, :user])
    |> Repo.one()
  end

  @doc """
  Gets records for a user within a date range.
  """
  def list_by_user_and_date_range(user_id, start_date, end_date) do
    Record
    |> where([r], r.userId == ^user_id)
    |> where([r], r.started_at >= ^start_date and r.started_at <= ^end_date)
    |> where([r], is_nil(r.deleted_at))
    |> order_by([r], asc: r.started_at)
    |> Repo.all()
  end
end
