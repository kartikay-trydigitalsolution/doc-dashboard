defmodule FirmtechApi.Users.DynamoSync do
  @moduledoc """
  Enriches User structs with data stored in the DynamoDB User table.
  """
  alias ExAws.Dynamo
  alias FirmtechApi.Users.User
  require Logger

  @doc """
  Fetches user attributes from DynamoDB and populates the User struct.
  """
  def enrich_user(%User{id: id} = user) when is_binary(id) do
    case get_dynamo_user(id) do
      {:ok, item} when is_map(item) ->
        apply_dynamo_attributes(user, item)

      _ ->
        user
    end
  end

  def enrich_user(other), do: other

  @doc """
  Enriches a list of User structs concurrently.
  """
  def enrich_users(users) when is_list(users) do
    users
    |> Task.async_stream(&enrich_user/1, max_concurrency: 10, timeout: 5000)
    |> Enum.map(fn
      {:ok, user} -> user
      {:exit, _reason} -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  def enrich_users(other), do: other

  defp get_dynamo_user(user_id) do
    table = get_table_name()

    if table do
      case Dynamo.get_item(table, %{"id" => user_id}) |> ExAws.request() do
        {:ok, %{"Item" => raw_item}} ->
          {:ok, Dynamo.Decoder.decode(raw_item)}

        {:ok, _} ->
          {:error, :not_found}

        {:error, reason} ->
          Logger.warning("DynamoDB get_item failed for user #{user_id}: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, :no_table_configured}
    end
  end

  defp get_table_name do
    Application.get_env(:firmtech_api, :user_table) ||
      System.get_env("DYNAMO_USER_TABLE") ||
      System.get_env("USER_TABLE_NAME") ||
      "User-5y2dtm3mmvhefcdnxzfzdvmojy-NONE"
  end

  defp apply_dynamo_attributes(%User{} = user, item) when is_map(item) do
    medications_data =
      case Map.get(item, "medications_data") do
        binary when is_binary(binary) ->
          case Jason.decode(binary) do
            {:ok, decoded} -> decoded
            _ -> %{}
          end

        map when is_map(map) ->
          map

        _ ->
          nil
      end

    sleep = parse_integer(Map.get(item, "sleep"))
    stress = parse_integer(Map.get(item, "stress"))
    shim_score = parse_integer(Map.get(item, "shim_score"))
    erection_hardness_score = parse_integer(Map.get(item, "erection_hardness_score"))
    ehs_score = parse_integer(Map.get(item, "ehs_score")) || erection_hardness_score
    weight = parse_decimal(Map.get(item, "weight")) || user.weight
    height = parse_decimal(Map.get(item, "height")) || user.height

    tobacco_bool =
      case Map.get(item, "tobacco") do
        val when val in ["none", "no", nil, false] -> false
        _ -> true
      end

    alcohol_bool =
      case Map.get(item, "alcohol") do
        val when val in ["none", "no", nil, false] -> false
        _ -> true
      end

    tobacco = if is_nil(user.tobacco), do: tobacco_bool, else: user.tobacco
    alcohol = if is_nil(user.alcohol), do: alcohol_bool, else: user.alcohol
    tobacco_comments = user.tobacco_comments || Map.get(item, "tobacco")
    alcohol_comments = user.alcohol_comments || Map.get(item, "alcohol")

    %{
      user
      | # Virtual fields from DynamoDB
        language_code: Map.get(item, "language_code") || user.language_code,
        notifications_enabled: Map.get(item, "notifications_enabled", user.notifications_enabled),
        push_token: Map.get(item, "push_token") || user.push_token,
        relationship_status: Map.get(item, "relationship_status") || user.relationship_status,
        relationship_orientation:
          Map.get(item, "relationship_orientation") || user.relationship_orientation,
        activity_level: Map.get(item, "activity_level") || user.activity_level,
        goals: Map.get(item, "goals") || user.goals,
        health_conditions: Map.get(item, "health_conditions") || user.health_conditions,
        medications_data: medications_data || user.medications_data,
        cannabis: Map.get(item, "cannabis") || user.cannabis,
        sleep: sleep || user.sleep,
        stress: stress || user.stress,
        q1: Map.get(item, "q1") || user.q1,
        q2: Map.get(item, "q2") || user.q2,
        q3: Map.get(item, "q3") || user.q3,
        q4: Map.get(item, "q4") || user.q4,
        q5: Map.get(item, "q5") || user.q5,
        q6: Map.get(item, "q6") || user.q6,
        q7: Map.get(item, "q7") || user.q7,
        q8: Map.get(item, "q8") || user.q8,
        user_consent: Map.get(item, "user_consent") || user.user_consent,

        # Schema fields (if not set in Postgres or available in Dynamo)
        permanent_residency_country_code:
          Map.get(item, "permanent_residency_country_code") ||
            user.permanent_residency_country_code,
        erection_hardness: Map.get(item, "erection_hardness") || user.erection_hardness,
        erection_hardness_score: erection_hardness_score || user.erection_hardness_score,
        ehs_score: ehs_score || user.ehs_score,
        shim_score: shim_score || user.shim_score,
        shim_severity: Map.get(item, "shim_severity") || user.shim_severity,
        performance_data: Map.get(item, "performance_data") || user.performance_data,
        weight: weight,
        height: height,
        tobacco: tobacco,
        alcohol: alcohol,
        tobacco_comments: tobacco_comments,
        alcohol_comments: alcohol_comments,
        onboarded: Map.get(item, "onboarded", user.onboarded)
    }
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(int) when is_integer(int), do: int

  defp parse_integer(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp parse_integer(num) when is_number(num), do: trunc(num)
  defp parse_integer(_), do: nil

  defp parse_decimal(nil), do: nil
  defp parse_decimal(%Decimal{} = dec), do: dec
  defp parse_decimal(num) when is_number(num), do: Decimal.from_float(num * 1.0)

  defp parse_decimal(str) when is_binary(str) do
    case Decimal.parse(str) do
      {dec, _} -> dec
      :error -> nil
    end
  end

  defp parse_decimal(_), do: nil
end
