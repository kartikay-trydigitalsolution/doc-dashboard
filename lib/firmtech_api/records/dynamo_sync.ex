defmodule FirmtechApi.Records.DynamoSync do
  @moduledoc """
  Synchronizes records and record results from DynamoDB into PostgreSQL.
  """
  require Logger
  alias FirmtechApi.Repo
  alias FirmtechApi.Records.Record
  alias FirmtechApi.RecordResults.RecordResult

  @default_table "Record-5y2dtm3mmvhefcdnxzfzdvmojy-NONE"
  @index_name "byUserIdbyStartedAt"

  @valid_erection_classes ~w(SEX SOLO SLEEP UNKNOWN FALSE MORNING OTHER)

  @doc """
  Queries DynamoDB for all records belonging to `user_id` and upserts them
  into the PostgreSQL `records` and `recordsResults` tables.
  """
  def sync_user_records(user_id) when is_binary(user_id) do
    table = System.get_env("DYNAMO_RECORD_TABLE") || @default_table

    query_req =
      ExAws.Dynamo.query(
        table,
        index_name: @index_name,
        key_condition_expression: "userId = :uid",
        expression_attribute_values: [uid: user_id]
      )

    case ExAws.request(query_req) do
      {:ok, %{"Items" => items}} when is_list(items) ->
        records =
          Enum.map(items, fn raw_item ->
            item = ExAws.Dynamo.Decoder.decode(raw_item)
            sync_single_record(item, user_id)
          end)
          |> Enum.reject(&is_nil/1)

        {:ok, records}

      {:error, reason} ->
        Logger.warning("Failed to query records from DynamoDB for user #{user_id}: #{inspect(reason)}")
        {:error, reason}

      other ->
        Logger.warning("Unexpected response querying records from DynamoDB for user #{user_id}: #{inspect(other)}")
        {:ok, []}
    end
  rescue
    e ->
      Logger.error("Exception during DynamoSync for records of user #{user_id}: #{inspect(e)}")
      {:error, e}
  end

  def sync_user_records(_), do: {:ok, []}

  defp sync_single_record(%{"id" => id} = item, user_id) when is_binary(id) do
    started_at = parse_datetime(item["started_at"])
    fw_version = parse_fw_version(item["fw_version"])
    score = parse_decimal(item["score"])
    recording_area = parse_decimal(item["recording_area"])

    attrs = %{
      id: id,
      userId: user_id,
      started_at: started_at,
      started_at_unix_timestamp: item["started_at_unix_timestamp"],
      timeZoneOffsetMinutes: item["timeZoneOffsetMinutes"],
      duration: item["duration"] || 0,
      score: score,
      sex_count: item["sex_count"] || 0,
      sex_rating: item["sex_rating"] || 0,
      recreational_drugs: item["recreational_drugs"] || false,
      slept: item["slept"] || false,
      solo_count: item["solo_count"] || 0,
      consumed_alcohol_units: item["consumed_alcohol_units"] || 0,
      fw_version: fw_version,
      app_version: item["app_version"],
      clusters_marked_by_user: item["clusters_marked_by_user"] || 0,
      personal_comments: item["personal_comments"],
      prescription_drugs_array: item["prescription_drugs_array"],
      recording_area: recording_area,
      _replicated: true
    }

    record =
      case Repo.get_by(Record, id: id) do
        nil ->
          %Record{}
          |> Record.changeset(attrs)
          |> Repo.insert()

        existing_record ->
          existing_record
          |> Record.changeset(attrs)
          |> Repo.update()
      end

    case record do
      {:ok, saved_record} ->
        sync_record_results(saved_record, item)
        saved_record

      {:error, changeset} ->
        Logger.error("Failed to upsert record #{id}: #{inspect(changeset.errors)}")
        nil
    end
  end

  defp sync_single_record(_, _), do: nil

  defp sync_record_results(%Record{sid: record_sid}, item) do
    raw_results = item["results"]
    results = decode_json_if_needed(raw_results)

    raw_user_info = item["results_user_info"]
    user_info = decode_json_if_needed(raw_user_info)

    user_info_map =
      if is_list(user_info) do
        Enum.into(user_info, %{}, fn
          %{"cluster" => c, "class" => cls} -> {c, cls}
          _ -> {nil, nil}
        end)
      else
        %{}
      end

    if is_list(results) do
      Enum.each(results, fn cluster_data ->
        sync_single_cluster(record_sid, cluster_data, user_info_map)
      end)
    end
  end

  defp sync_single_cluster(record_sid, %{"cluster" => cluster_num} = cluster_data, user_info_map) do
    start_dt = parse_naive_datetime(cluster_data["start"])
    end_dt = parse_naive_datetime(cluster_data["end"])
    firmness = parse_decimal(cluster_data["firmness"])
    global_best_score = parse_decimal(cluster_data["global_best_score"])
    erection_class = parse_erection_class(Map.get(user_info_map, cluster_num))

    attrs = %{
      record_sid: record_sid,
      cluster: cluster_num,
      start: start_dt,
      end: end_dt,
      firmness: firmness,
      global_best_score: global_best_score,
      erection_class: erection_class,
      time_4_to_6: round_int(cluster_data["time_4_to_6"]),
      time_6_to_8: round_int(cluster_data["time_6_to_8"]),
      time_8_to_10: round_int(cluster_data["time_8_to_10"])
    }

    case Repo.get_by(RecordResult, record_sid: record_sid, cluster: cluster_num) do
      nil ->
        %RecordResult{}
        |> RecordResult.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> RecordResult.changeset(attrs)
        |> Repo.update()
    end
  end

  defp sync_single_cluster(_, _, _), do: nil

  defp decode_json_if_needed(nil), do: []
  defp decode_json_if_needed(val) when is_binary(val) do
    case Jason.decode(val) do
      {:ok, decoded} -> decoded
      _ -> []
    end
  end
  defp decode_json_if_needed(val) when is_list(val), do: val
  defp decode_json_if_needed(_), do: []

  defp parse_datetime(nil), do: nil
  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end
  defp parse_datetime(_), do: nil

  defp parse_naive_datetime(nil), do: nil
  defp parse_naive_datetime(str) when is_binary(str) do
    normalized = String.replace(str, " ", "T")
    case NaiveDateTime.from_iso8601(normalized) do
      {:ok, ndt} -> ndt
      _ ->
        case DateTime.from_iso8601(str) do
          {:ok, dt, _} -> DateTime.to_naive(dt)
          _ -> nil
        end
    end
  end
  defp parse_naive_datetime(_), do: nil

  defp parse_fw_version(nil), do: nil
  defp parse_fw_version(ver) when is_integer(ver), do: ver
  defp parse_fw_version(str) when is_binary(str) do
    clean = String.replace(str, ".", "")
    case Integer.parse(clean) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_fw_version(_), do: nil

  defp parse_decimal(nil), do: nil
  defp parse_decimal(%Decimal{} = d), do: d
  defp parse_decimal(num) when is_number(num) do
    Decimal.from_float(num * 1.0)
  rescue
    _ -> nil
  end
  defp parse_decimal(str) when is_binary(str) do
    case Decimal.parse(str) do
      {d, _} -> d
      :error -> nil
    end
  end
  defp parse_decimal(_), do: nil

  defp parse_erection_class(nil), do: nil
  defp parse_erection_class(cls) when is_binary(cls) do
    upper = String.upcase(cls)
    if upper in @valid_erection_classes do
      String.to_existing_atom(upper)
    else
      nil
    end
  rescue
    _ -> nil
  end
  defp parse_erection_class(cls) when is_atom(cls), do: cls
  defp parse_erection_class(_), do: nil

  defp round_int(nil), do: nil
  defp round_int(num) when is_integer(num), do: num
  defp round_int(num) when is_float(num), do: round(num)
  defp round_int(str) when is_binary(str) do
    case Float.parse(str) do
      {f, _} -> round(f)
      :error -> nil
    end
  end
  defp round_int(_), do: nil
end
