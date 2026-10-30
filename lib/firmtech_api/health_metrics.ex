defmodule FirmtechApi.HealthMetrics do
  # TODO: these examples only ..

  @moduledoc """
  The HealthMetrics context.
  This module provides a unified API to work with users, records, results, and performance data.
  """

  alias FirmtechApi.Users.User
  alias FirmtechApi.Records.Record
  alias FirmtechApi.RecordResults.RecordResult
  alias FirmtechApi.PerformanceDatas.PerformanceData
  alias FirmtechApi.Repo

  import Ecto.Query

  # User-related functions

  def get_user(id), do: User.get(id)
  def get_user!(id), do: User.get!(id)
  def create_user(attrs), do: User.create(attrs)
  def update_user(user, attrs), do: User.update(user, attrs)
  def delete_user(user), do: User.delete(user)
  def list_active_users, do: User.list_active()

  # Record-related functions

  def get_record(sid), do: Record.get(sid)
  def get_record!(sid), do: Record.get!(sid)
  def get_record_by_uuid(uuid), do: Record.get_by_uuid(uuid)
  def create_record(attrs), do: Record.create(attrs)
  def update_record(record, attrs), do: Record.update(record, attrs)
  def delete_record(record), do: Record.delete(record)
  def list_user_records(user_id), do: Record.list_by_user(user_id)

  # Record Result-related functions

  def get_record_result(record_sid, cluster), do: RecordResult.get(record_sid, cluster)
  def create_record_result(attrs), do: RecordResult.create(attrs)
  def update_record_result(result, attrs), do: RecordResult.update(result, attrs)
  def delete_record_result(result), do: RecordResult.delete(result)
  def list_record_results(record_sid), do: RecordResult.list_by_record(record_sid)

  # Performance Data-related functions

  def get_latest_performance_data(user_id), do: PerformanceData.get_latest_for_user(user_id)
  def create_performance_data(attrs), do: PerformanceData.create(attrs)
  def update_performance_data(data, attrs), do: PerformanceData.update(data, attrs)

  # Complex business logic functions

  @doc """
  Gets a user's complete data profile including latest records and performance metrics.
  """
  def get_user_profile(user_id) do
    user = get_user!(user_id)

    # Get the latest 5 records
    latest_records =
      Record
      |> where([r], r.userId == ^user_id and is_nil(r.deleted_at))
      |> order_by([r], desc: r.started_at)
      |> limit(5)
      |> preload([:results])
      |> Repo.all()

    # Get the latest performance data
    performance_data = get_latest_performance_data(user_id)

    # Compile the complete profile
    %{
      user: user,
      latest_records: latest_records,
      performance_data: performance_data
    }
  end

  @doc """
  Calculates and updates a user's BMI based on their height and weight.
  """
  def calculate_and_update_bmi(user_id) do
    user = get_user!(user_id)

    with {:ok, height} <- get_height_in_meters(user),
         {:ok, weight} <- get_weight_in_kg(user) do
      # BMI formula: weight (kg) / (height (m))²
      bmi = Decimal.div(weight, Decimal.mult(height, height))
      bmi = Decimal.round(bmi, 2)

      update_user(user, %{bmi: bmi})
    else
      _ -> {:error, :missing_height_or_weight}
    end
  end

  # Helper functions for the BMI calculation
  defp get_height_in_meters(user) do
    case {user.height, user.height_unit} do
      {nil, _} ->
        {:error, :missing_height}

      {height, :CM} ->
        {:ok, Decimal.div(height, Decimal.new(100))}

      {height, :IN} ->
        # Convert inches to meters (1 inch = 0.0254 meters)
        {:ok, Decimal.mult(height, Decimal.new("0.0254"))}
    end
  end

  defp get_weight_in_kg(user) do
    case {user.weight, user.weight_unit} do
      {nil, _} ->
        {:error, :missing_weight}

      {weight, :KG} ->
        {:ok, weight}

      {weight, :LB} ->
        # Convert pounds to kg (1 lb = 0.45359237 kg)
        {:ok, Decimal.mult(weight, Decimal.new("0.45359237"))}
    end
  end

  @doc """
  Gets user's progress over time by analyzing records and performance data.
  """
  def get_user_progress(user_id, start_date, end_date) do
    # Get records in the date range
    records = Record.list_by_user_and_date_range(user_id, start_date, end_date)

    # Group performance data by week or month for trend analysis
    performance_trends =
      PerformanceData
      |> where([pd], pd.user_id == ^user_id)
      |> where([pd], pd.updated_at >= ^NaiveDateTime.from_erl!(:calendar.universal_time()))
      |> where([pd], pd.updated_at <= ^NaiveDateTime.from_erl!(:calendar.universal_time()))
      |> order_by([pd], asc: pd.updated_at)
      |> Repo.all()

    # Analyze the data and return meaningful metrics
    %{
      records_count: length(records),
      avg_score: calculate_average_score(records),
      performance_trends: performance_trends,
      improvement: calculate_improvement(performance_trends)
    }
  end

  defp calculate_average_score(records) do
    if Enum.empty?(records) do
      nil
    else
      total =
        Enum.reduce(records, Decimal.new(0), fn record, acc ->
          if record.score, do: Decimal.add(acc, record.score), else: acc
        end)

      count = Enum.count(records, & &1.score)

      if count > 0 do
        Decimal.div(total, Decimal.new(count))
      else
        nil
      end
    end
  end

  defp calculate_improvement(performance_data) do
    if length(performance_data) >= 2 do
      first = List.first(performance_data)
      last = List.last(performance_data)

      if first.erectile_fitness_score && last.erectile_fitness_score do
        # Calculate percentage improvement
        delta = Decimal.sub(last.erectile_fitness_score, first.erectile_fitness_score)

        percentage =
          Decimal.mult(
            Decimal.div(delta, first.erectile_fitness_score),
            Decimal.new(100)
          )

        Decimal.round(percentage, 2)
      else
        nil
      end
    else
      nil
    end
  end

  @doc """
  Creates a new record with results and triggers performance data calculation.
  """
  def create_record_with_results(record_attrs, results_attrs) do
    Repo.transaction(fn ->
      # Create the record first
      {:ok, record} = create_record(record_attrs)

      # Create all the result entries for this record
      results =
        Enum.map(results_attrs, fn result_attr ->
          attrs = Map.put(result_attr, :record_sid, record.sid)
          {:ok, result} = create_record_result(attrs)
          result
        end)

      # Trigger performance data calculation
      generate_performance_data(record)

      {record, results}
    end)
  end

  @doc """
  Generates performance data metrics based on a record and its results.
  """
  def generate_performance_data(record) do
    user_id = record.userId

    # Get all records for this user
    records = list_user_records(user_id)

    # Calculate performance metrics
    metrics = calculate_performance_metrics(user_id, records)

    # Create or update performance data
    performance_data_attrs =
      Map.merge(metrics, %{
        user_id: user_id,
        updated_at: NaiveDateTime.utc_now(),
        record_sid: record.sid,
        performance_data_trigger: :post_insert_record
      })

    create_performance_data(performance_data_attrs)
  end

  @doc """
  Calculates performance metrics based on user's records.
  """
  def calculate_performance_metrics(user_id, records) do
    # Extract all record results
    record_sids = Enum.map(records, & &1.sid)

    results_query =
      RecordResult
      |> where([rr], rr.record_sid in ^record_sids)
      |> Repo.all()

    results_by_record = Enum.group_by(results_query, & &1.record_sid)

    # Basic metrics
    record_count = length(records)

    # Erection type metrics
    nocturnal_results = Enum.filter(results_query, &(&1.erection_class == :SLEEP))

    solo_sex_results =
      Enum.filter(results_query, fn r ->
        r.erection_class == :SOLO || r.erection_class == :SEX
      end)

    # Calculate averages and counts
    avg_firmness = calculate_avg_firmness(results_query)
    avg_nocturnal_firmness = calculate_avg_firmness(nocturnal_results)
    avg_sex_solo_firmness = calculate_avg_firmness(solo_sex_results)

    # Duration calculations
    nocturnal_duration = calculate_total_duration(nocturnal_results)
    sex_solo_duration = calculate_total_duration(solo_sex_results)

    # Weekly averages - assuming records span multiple weeks
    weeks_span = calculate_weeks_span(records)

    # Erectile fitness score calculation (simplified for example)
    erectile_fitness_score =
      calculate_fitness_score(
        avg_firmness,
        record_count,
        length(nocturnal_results),
        length(solo_sex_results)
      )

    %{
      erectile_fitness_score: erectile_fitness_score,
      avg_firmness_score: avg_firmness,
      avg_nocturnal_firmness_score: avg_nocturnal_firmness,
      record_count: record_count,
      avg_erections_per_week:
        if(weeks_span > 0,
          do: Decimal.div(Decimal.new(record_count), Decimal.new(weeks_span)),
          else: nil
        ),
      total_erections: length(results_query),
      solo_sex_count: length(solo_sex_results),
      nocturnal_count: length(nocturnal_results),
      avg_nocturnal_erections_per_week:
        if(weeks_span > 0,
          do: Decimal.div(Decimal.new(length(nocturnal_results)), Decimal.new(weeks_span)),
          else: nil
        ),
      avg_firmness_score__nocturnal: avg_nocturnal_firmness,
      avg_firmness_score__sex_solo: avg_sex_solo_firmness,
      avg_total_duration__nocturnal:
        Decimal.to_integer(
          Decimal.div(
            Decimal.new(nocturnal_duration),
            Decimal.new(max(length(nocturnal_results), 1))
          )
        ),
      avg_total_duration__sex_solo:
        Decimal.to_integer(
          Decimal.div(
            Decimal.new(sex_solo_duration),
            Decimal.new(max(length(solo_sex_results), 1))
          )
        ),
      duration_of_sleep_erections_in_seconds: nocturnal_duration,
      duration_of_sex_solo_erections_in_seconds: sex_solo_duration
    }
  end

  defp calculate_avg_firmness(results) do
    if Enum.empty?(results) do
      nil
    else
      total =
        Enum.reduce(results, Decimal.new(0), fn result, acc ->
          if result.firmness, do: Decimal.add(acc, result.firmness), else: acc
        end)

      count = Enum.count(results, & &1.firmness)

      if count > 0 do
        Decimal.div(total, Decimal.new(count))
        |> Decimal.round(2)
      else
        nil
      end
    end
  end

  defp calculate_total_duration(results) do
    Enum.reduce(results, 0, fn result, acc ->
      # Calculate duration between start and end timestamps
      if result.start && result.end do
        duration_seconds = NaiveDateTime.diff(result.end, result.start)
        acc + duration_seconds
      else
        acc
      end
    end)
  end

  defp calculate_weeks_span(records) do
    if Enum.empty?(records) do
      0
    else
      sorted_records = Enum.sort_by(records, & &1.started_at, DateTime)
      first_date = List.first(sorted_records).started_at
      last_date = List.last(sorted_records).started_at

      # Calculate difference in seconds and convert to weeks
      diff_seconds = DateTime.diff(last_date, first_date)
      # 604800 seconds in a week
      diff_weeks = max(div(diff_seconds, 604_800), 1)
      diff_weeks
    end
  end

  defp calculate_fitness_score(avg_firmness, record_count, nocturnal_count, sex_solo_count) do
    # This is a simplified example formula - you would define your own algorithm
    cond do
      avg_firmness == nil ->
        nil

      true ->
        base_score = avg_firmness

        # Add bonuses for frequency and variety
        # Cap at 1.0
        frequency_factor = min(record_count / 10, 1.0)

        variety_factor =
          cond do
            nocturnal_count > 0 && sex_solo_count > 0 -> 1.0
            nocturnal_count > 0 || sex_solo_count > 0 -> 0.7
            true -> 0.5
          end

        # Combine factors
        score = Decimal.mult(base_score, Decimal.new(frequency_factor))
        score = Decimal.mult(score, Decimal.new(variety_factor))

        # Scale to 0-100 and round
        score = Decimal.mult(score, Decimal.new(100))
        Decimal.round(score, 2)
    end
  end

  @doc """
  Gets all risk factors for a user based on their profile and records.
  """
  def get_user_risk_factors(user_id) do
    user = get_user!(user_id)
    performance_data = get_latest_performance_data(user_id)

    risk_factors = []

    # Check medical conditions
    risk_factors = if user.diabetes, do: ["Diabetes" | risk_factors], else: risk_factors
    risk_factors = if user.hypertension, do: ["Hypertension" | risk_factors], else: risk_factors

    # Check lifestyle factors
    risk_factors = if user.tobacco, do: ["Tobacco use" | risk_factors], else: risk_factors
    risk_factors = if user.alcohol, do: ["Alcohol consumption" | risk_factors], else: risk_factors

    risk_factors =
      if user.recreational_drugs, do: ["Recreational drug use" | risk_factors], else: risk_factors

    # Check performance metrics if available
    risk_factors =
      if performance_data && performance_data.erectile_fitness_score &&
           Decimal.compare(performance_data.erectile_fitness_score, Decimal.new(50)) == :lt,
         do: ["Low erectile fitness score" | risk_factors],
         else: risk_factors

    # Add BMI-related risk if applicable
    risk_factors =
      if user.bmi && Decimal.compare(user.bmi, Decimal.new(30)) == :gt,
        do: ["Obesity" | risk_factors],
        else: risk_factors

    # Return sorted list
    Enum.sort(risk_factors)
  end

  @doc """
  Archives old records that are no longer needed for active analysis.
  """
  def archive_old_records(user_id, cutoff_date) do
    Record
    |> where([r], r.userId == ^user_id)
    |> where([r], r.started_at < ^cutoff_date)
    |> where([r], is_nil(r.deleted_at))
    |> Repo.update_all(set: [deleted_at: NaiveDateTime.utc_now()])
  end
end
