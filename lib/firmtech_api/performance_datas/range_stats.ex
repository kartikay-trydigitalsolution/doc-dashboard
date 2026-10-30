defmodule FirmtechApi.PerformanceDatas.RangeStats do
  @moduledoc """
  Computes `performance_data` for a user over an explicit `from`/`to` date range.

  This mirrors the aggregation performed by the `processRScore` lambda for a
  dashboard (RestApi) query: the requested local dates are shifted by
  `utc_offset` (minutes) for time-frame sensitive queries, while record counts
  use the un-shifted dates. The same aggregate SQL and erectile fitness score
  formula are used so the Elixir API is the source of truth for range-scoped
  statistics without depending on the lambda's fixed last-30-days window.
  """

  alias FirmtechApi.Repo

  @avg_firmness_query """
  SELECT
    ROUND(COUNT(rr.cluster) / 4.285) AS avg_erections_per_week,
    AVG(rr.firmness) AS avg_firmness_score,
    FLOOR(EXTRACT (EPOCH FROM AVG(rr.end - rr.start))) AS avg_duration
  FROM "recordsResults" rr
  LEFT JOIN records r
  ON r.sid = rr.record_sid
  WHERE r."userId" = $1
  AND r.deleted_at IS NULL
  AND CAST("start" AS timestamp) BETWEEN $2 AND $3
  AND rr.erection_class NOT IN ('FALSE')
  """

  @avg_firmness_nocturnal_query """
  SELECT
    AVG(rr.firmness) AS avg_firmness_score__nocturnal
  FROM "recordsResults" rr
  LEFT JOIN records r
  ON r.sid = rr.record_sid
  WHERE r."userId" = $1
  AND r.deleted_at IS NULL
  AND CAST("start" AS timestamp) BETWEEN $2 AND $3
  AND rr.erection_class IN ('SLEEP', 'MORNING')
  """

  @avg_firmness_sex_solo_query """
  SELECT
    AVG(rr.firmness) AS avg_firmness_score__sex_solo
  FROM "recordsResults" rr
  LEFT JOIN records r
  ON r.sid = rr.record_sid
  WHERE r."userId" = $1
  AND r.deleted_at IS NULL
  AND CAST("start" AS timestamp) BETWEEN $2 AND $3
  AND rr.erection_class IN ('SEX', 'SOLO')
  """

  @record_count_query """
  SELECT COUNT(id) AS record_count FROM records r
  WHERE r."userId" = $1
  AND r.deleted_at IS NULL
  AND r.started_at BETWEEN $2 AND $3
  """

  @clusters_summary_query """
  SELECT
    SUM(total_erections) AS total_erections,
    SUM(total_sleep_erections) AS total_sleep_erections,
    SUM(total_sex_solo_erections) AS total_sex_solo_erections,
    COUNT(DISTINCT(record_with_sex_solo)) AS record_with_sex_solo,
    COUNT(DISTINCT(record_with_sleep)) AS record_with_sleep,
    SUM(duration_of_sleep_erections_in_seconds) AS duration_of_sleep_erections_in_seconds,
    CAST((SUM(duration_of_sleep_erections_in_seconds) / NULLIF(COUNT(DISTINCT(record_with_sleep)),0) ) AS integer) as avg_total_duration__nocturnal,
    CAST(SUM(duration_of_sex_solo_erections_in_seconds) AS integer) AS duration_of_sex_solo_erections_in_seconds,
    CAST((SUM(duration_of_sex_solo_erections_in_seconds) / NULLIF(COUNT(DISTINCT(record_with_sex_solo)),0) ) AS integer) as avg_total_duration__sex_solo,
    CAST(SUM(total_sleep_erections) / NULLIF(COUNT(DISTINCT(record_with_sleep)),0) AS numeric) as avg_count__nocturnal,
    CAST(SUM(total_sex_solo_erections) / NULLIF(COUNT(DISTINCT(record_with_sex_solo)),0) AS numeric) as avg_count__sex_solo
  FROM
    (
      SELECT
        CASE
          WHEN rr.erection_class NOT IN ('FALSE') THEN COUNT(rr.cluster)
          ELSE 0
        END AS total_erections,
        CASE
          WHEN rr.erection_class IN ('SLEEP', 'MORNING') THEN COUNT(rr.cluster)
          ELSE 0
        END AS total_sleep_erections,
        CASE
          WHEN rr.erection_class IN ('SEX', 'SOLO') THEN COUNT(rr.cluster)
          ELSE 0
        END AS total_sex_solo_erections,
        CASE
          WHEN rr.erection_class IN ('SEX', 'SOLO') THEN rr.record_sid
          ELSE null
        END AS record_with_sex_solo,
        CASE
          WHEN rr.erection_class IN ('SLEEP', 'MORNING') THEN rr.record_sid
          ELSE null
        END AS record_with_sleep,
        CASE
          WHEN rr.erection_class IN ('SLEEP', 'MORNING') THEN sum(EXTRACT(EPOCH FROM (rr."end" - rr."start")))
          ELSE 0
        END AS duration_of_sleep_erections_in_seconds,
        CASE
          WHEN rr.erection_class IN ('SEX', 'SOLO') THEN sum(EXTRACT(EPOCH FROM (rr."end" - rr."start")))
          ELSE 0
        END AS duration_of_sex_solo_erections_in_seconds
      FROM
        "recordsResults" rr
        LEFT JOIN records r ON r.sid = rr.record_sid
      WHERE
        r."userId" = $1
        AND r.deleted_at IS NULL
        AND CAST("start" AS timestamp) BETWEEN $2 AND $3
      GROUP BY
        r.id, rr.erection_class, rr.record_sid
    ) AS summary
  """

  @counts_summary_query """
  SELECT
    COUNT(id) AS record_count,
    SUM(total_recordings_with_sleep) as total_recordings_with_sleep,
    SUM(solo_count + sex_count) AS solo_sex_count,
    SUM(solo_count_with_sleep + sex_count_with_sleep) AS solo_sex_count_with_sleep
  FROM
    (
      SELECT
        r.id,
        CASE
          WHEN r.slept = TRUE THEN 1
          ELSE 0
        END AS total_recordings_with_sleep,
        CASE
          WHEN r.slept = TRUE THEN r.solo_count
          ELSE 0
        END AS solo_count_with_sleep,
        CASE
          WHEN r.slept = TRUE THEN r.sex_count
          ELSE 0
        END AS sex_count_with_sleep,
        r.solo_count,
        r.sex_count
      FROM
        records r
      WHERE
        r."userId" = $1
        AND r.deleted_at IS NULL
        AND r.started_at BETWEEN $2 AND $3
      GROUP BY
        r.id, r.slept, r.solo_count, r.sex_count
    ) AS summary
  """

  @clusters_summary_legacy_query """
  SELECT
    SUM(total_erections) AS total_erections,
    SUM(total_erections_with_sleep) AS total_erections_with_sleep
  FROM
    (
      SELECT
        COUNT(rr.cluster) AS total_erections,
        CASE
          WHEN r.slept = TRUE THEN COUNT(rr.cluster)
          ELSE 0
        END AS total_erections_with_sleep
      FROM
        "recordsResults" rr
        LEFT JOIN records r ON r.sid = rr.record_sid
      WHERE
        r."userId" = $1
        AND r.deleted_at IS NULL
        AND CAST("start" AS timestamp) BETWEEN $2 AND $3
        AND rr.erection_class NOT IN ('FALSE')
      GROUP BY
        r.id, r.slept
    ) AS summary
  """

  @last_record_within_range_query """
  SELECT
    r.id as record_id,
    r.sid,
    to_char(r.started_at, 'YYYY-MM-DD') AS started_at,
    COUNT(rr.record_sid) AS results_count
  FROM
    "records" r
    LEFT JOIN
    "recordsResults" rr
    ON
    r.sid = rr.record_sid
  WHERE
    r."userId" = $1
    AND r.started_at BETWEEN $2 AND $3
    AND r.deleted_at IS NULL
  GROUP BY
    r.id, r.sid, r.started_at
  ORDER BY
    r.started_at DESC
  LIMIT 1
  """

  @doc """
  Returns a `getUser`-shaped map with range-scoped `performance_data`.

  `from` and `to` are local date strings (`YYYY-MM-DD`); `utc_offset` is the
  client's offset from UTC in minutes.
  """
  def compute(user_id, from, to, utc_offset \\ 0) do
    offset = to_int(utc_offset)
    from_naive = naive("#{from} 00:00:00")
    to_naive = naive("#{to} 23:59:59")
    from_dt = utc(from_naive)
    to_dt = utc(to_naive)
    from_tz = shift(from_naive, offset)
    to_tz = shift(to_naive, offset)

    app_version = latest_app_version(user_id)

    performance_data =
      %{
        "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "erectile_fitness_score" => 0.0,
        "avg_firmness_score" => 0.0,
        "avg_firmness_score__nocturnal" => 0.0,
        "avg_firmness_score__sex_solo" => 0.0,
        "avg_nocturnal_firmness_score" => 0.0,
        "avg_erections_per_week" => 0.0,
        "avg_duration" => 0.0,
        "record_count" => 0,
        "total_erections" => 0,
        "solo_sex_count" => 0,
        "nocturnal_count" => 0,
        "avg_nocturnal_erections_per_week" => 0.0,
        "avg_nocturnal_erections" => 0.0,
        "avg_total_duration__nocturnal" => 0,
        "avg_total_duration__sex_solo" => 0,
        "avg_duration_of_sleep_erections_in_seconds" => 0,
        "avg_count__nocturnal" => 0.0,
        "avg_count__sex_solo" => 0.0,
        "duration_of_sleep_erections_in_seconds" => 0,
        "duration_of_sex_solo_erections_in_seconds" => 0
      }
      |> merge_avg_firmness(user_id, from_tz, to_tz)
      |> merge_cluster_summaries(user_id, from_dt, to_dt, from_tz, to_tz, app_version)
      |> put_fitness_score()

    %{
      "id" => user_id,
      "performance_data" => performance_data,
      "pushNotificationTokens" => %{},
      "last_open_app_at" => nil
    }
    |> Map.merge(last_record_within_range(user_id, from_dt, to_dt))
  end

  defp merge_avg_firmness(pd, user_id, from_tz, to_tz) do
    avg_firmness =
      user_id
      |> query(@avg_firmness_query, from_tz, to_tz)
      |> List.first() || %{}

    nocturnal =
      user_id
      |> query(@avg_firmness_nocturnal_query, from_tz, to_tz)
      |> List.first() || %{}

    sex_solo =
      user_id
      |> query(@avg_firmness_sex_solo_query, from_tz, to_tz)
      |> List.first() || %{}

    firmness = num(avg_firmness["avg_firmness_score"])

    pd
    |> Map.put("avg_firmness_score", firmness)
    |> Map.put("avg_nocturnal_firmness_score", firmness)
    |> Map.put("avg_erections_per_week", num(avg_firmness["avg_erections_per_week"]))
    |> Map.put("avg_duration", num(avg_firmness["avg_duration"]))
    |> Map.put("avg_firmness_score__nocturnal", num(nocturnal["avg_firmness_score__nocturnal"]))
    |> Map.put("avg_firmness_score__sex_solo", num(sex_solo["avg_firmness_score__sex_solo"]))
  end

  defp merge_cluster_summaries(pd, user_id, from_dt, to_dt, from_tz, to_tz, app_version)
       when app_version > 260 do
    record_count = user_id |> query(@record_count_query, from_dt, to_dt) |> List.first() || %{}

    summary = user_id |> query(@clusters_summary_query, from_tz, to_tz) |> List.first() || %{}

    nocturnal_count = int(summary["total_sleep_erections"])
    record_with_sleep = int(summary["record_with_sleep"])
    avg_total_duration__nocturnal = int(summary["avg_total_duration__nocturnal"])

    avg_nocturnal_erections =
      if nocturnal_count > 0 and record_with_sleep > 0 do
        nocturnal_count / record_with_sleep
      else
        0.0
      end

    pd
    |> Map.put("record_count", int(record_count["record_count"]))
    |> Map.put("total_erections", int(summary["total_erections"]))
    |> Map.put("nocturnal_count", nocturnal_count)
    |> Map.put("solo_sex_count", int(summary["total_sex_solo_erections"]))
    |> Map.put("avg_nocturnal_erections", avg_nocturnal_erections)
    |> Map.put("avg_total_duration__nocturnal", avg_total_duration__nocturnal)
    |> Map.put("avg_duration_of_sleep_erections_in_seconds", avg_total_duration__nocturnal)
    |> Map.put("duration_of_sex_solo_erections_in_seconds", int(summary["duration_of_sex_solo_erections_in_seconds"]))
    |> Map.put("duration_of_sleep_erections_in_seconds", int(summary["duration_of_sleep_erections_in_seconds"]))
    |> Map.put("avg_total_duration__sex_solo", int(summary["avg_total_duration__sex_solo"]))
    |> Map.put("avg_count__nocturnal", num(summary["avg_count__nocturnal"]))
    |> Map.put("avg_count__sex_solo", num(summary["avg_count__sex_solo"]))
  end

  defp merge_cluster_summaries(pd, user_id, from_dt, to_dt, from_tz, to_tz, _app_version) do
    counts = user_id |> query(@counts_summary_query, from_dt, to_dt) |> List.first() || %{}
    clusters = user_id |> query(@clusters_summary_legacy_query, from_tz, to_tz) |> List.first() || %{}

    total_recordings_with_sleep = int(counts["total_recordings_with_sleep"])
    solo_sex_count_with_sleep = int(counts["solo_sex_count_with_sleep"])
    nocturnal_count = int(clusters["total_erections_with_sleep"]) - solo_sex_count_with_sleep

    avg_nocturnal_erections =
      if nocturnal_count > 0 and total_recordings_with_sleep > 0 do
        nocturnal_count / total_recordings_with_sleep
      else
        0.0
      end

    pd
    |> Map.put("record_count", int(counts["record_count"]))
    |> Map.put("solo_sex_count", int(counts["solo_sex_count"]))
    |> Map.put("total_erections", int(clusters["total_erections"]))
    |> Map.put("nocturnal_count", nocturnal_count)
    |> Map.put("avg_nocturnal_erections", avg_nocturnal_erections)
  end

  defp put_fitness_score(pd) do
    solo_sex_total_factor = interpolate(pd["solo_sex_count"], 0, 2, 2)
    nocturnal_avg_factor = interpolate(pd["avg_nocturnal_erections"], 0, 3, 3)
    avg_sex_solo_firmness_factor = interpolate(pd["avg_firmness_score__sex_solo"], 2, 8, 3)
    avg_nocturnal_firmness_factor = interpolate(pd["avg_firmness_score__nocturnal"], 2.5, 6.5, 4)

    avg_duration_nocturnal_in_minutes = pd["avg_total_duration__nocturnal"] / 60
    avg_duration_nocturnal_factor = interpolate(avg_duration_nocturnal_in_minutes, 0, 120, 4)

    score =
      round(
        (solo_sex_total_factor +
           nocturnal_avg_factor +
           avg_sex_solo_firmness_factor +
           avg_nocturnal_firmness_factor +
           avg_duration_nocturnal_factor) / 16 * 100
      ) / 10

    Map.put(pd, "erectile_fitness_score", score * 1.0)
  end

  defp interpolate(input, zero_anchor, full_anchor, max_points) do
    clamped = max(0.0, min(1.0, (input - zero_anchor) / (full_anchor - zero_anchor)))
    clamped * max_points
  end

  defp last_record_within_range(user_id, from_dt, to_dt) do
    case user_id |> query(@last_record_within_range_query, from_dt, to_dt) |> List.first() do
      nil ->
        %{
          "last_upload_record_id" => nil,
          "last_upload_at" => nil,
          "last_upload_cluster_count" => nil
        }

      row ->
        %{
          "last_upload_record_id" => uuid_to_string(row["record_id"]),
          "last_upload_at" => row["started_at"],
          "last_upload_cluster_count" => int(row["results_count"])
        }
    end
  end

  defp uuid_to_string(nil), do: nil
  defp uuid_to_string(<<_::128>> = uuid), do: Ecto.UUID.load!(uuid)
  defp uuid_to_string(uuid) when is_binary(uuid), do: uuid

  defp latest_app_version(user_id) do
    case Repo.query(
           ~s|SELECT app_version FROM records WHERE "userId" = $1 AND app_version IS NOT NULL ORDER BY started_at DESC LIMIT 1|,
           [Ecto.UUID.dump!(user_id)]
         ) do
      {:ok, %{rows: [[app_version]]}} -> parse_app_version(app_version)
      _ -> 260
    end
  end

  defp parse_app_version(nil), do: 260

  defp parse_app_version(app_version) when is_binary(app_version) do
    case app_version |> String.replace(~r/[^0-9]/, "") |> Integer.parse() do
      {value, _} -> value
      :error -> 260
    end
  end

  defp query(user_id, sql, from, to) do
    {:ok, %{columns: columns, rows: rows}} =
      Repo.query(sql, [Ecto.UUID.dump!(user_id), from, to])

    Enum.map(rows, fn row -> Map.new(Enum.zip(columns, row)) end)
  end

  defp shift(naive, offset_minutes) do
    NaiveDateTime.add(naive, offset_minutes * 60, :second)
  end

  defp naive(datetime) do
    {:ok, naive} = NaiveDateTime.from_iso8601(String.replace(datetime, " ", "T"))
    naive
  end

  defp utc(naive), do: DateTime.from_naive!(naive, "Etc/UTC")

  defp to_int(value) when is_integer(value), do: value
  defp to_int(value) when is_binary(value), do: String.to_integer(value)
  defp to_int(nil), do: 0

  defp num(nil), do: 0.0
  defp num(%Decimal{} = value), do: Decimal.to_float(value)
  defp num(value) when is_integer(value), do: value * 1.0
  defp num(value) when is_float(value), do: value

  defp int(nil), do: 0
  defp int(%Decimal{} = value), do: value |> Decimal.round(0, :down) |> Decimal.to_integer()
  defp int(value) when is_integer(value), do: value
  defp int(value) when is_float(value), do: trunc(value)
end
