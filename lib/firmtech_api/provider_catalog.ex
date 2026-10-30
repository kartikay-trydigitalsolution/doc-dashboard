defmodule FirmtechApi.ProviderCatalog do
  @moduledoc """
  Mirrors doctors into the DynamoDB `Provider` table.

  The app reads the provider list and the provider profile from DynamoDB
  (`queryProviders` / `getProviderById`), while the dashboard account and the
  patient link live in PostgreSQL (`staffs` / `user_staffs`). A doctor created
  from the dashboard needs a row in both places, with the same
  `affiliation_code`, so patients can link and the doctor can see them.

  Items are plain maps; `ExAws.Dynamo` annotates the DynamoDB types.
  """

  require Logger

  alias ExAws.Dynamo
  alias ExAws.Dynamo.Decoder

  @category_values ~w(UROLOGIST MEN_HEALTH FEMALE_PELVIC THERAPY PHYSIOTHERAPY CLINIC OTHER)

  def category_values, do: @category_values

  @doc """
  Creates or updates the provider for a doctor code.

  Returns `{:ok, provider_id, created?}`. When a provider with the same
  `affiliation_code` already exists its row is reused (fields not given here
  are preserved) and `created?` is false.
  """
  def upsert(%{affiliation_code: code} = attrs) when is_binary(code) do
    with {:ok, table} <- table_name(),
         existing <- find_by_code(code),
         :ok <- check_email_conflict(existing, attrs[:email]) do
      now = DateTime.utc_now() |> DateTime.to_iso8601()

      item =
        (existing || %{})
        |> Map.merge(provider_fields(attrs, now))
        |> Map.put("id", (existing && existing["id"]) || Ecto.UUID.generate())
        |> Map.put("__typename", "Provider")
        |> Map.put_new("created_at", now)
        |> Map.put_new("createdAt", now)
        |> Map.put("updatedAt", now)
        |> reject_nil()

      case Dynamo.put_item(table, item) |> ExAws.request() do
        {:ok, _response} ->
          {:ok, item["id"], is_nil(existing)}

        {:error, reason} ->
          Logger.error("[ProviderCatalog] put_item failed: #{inspect(reason)}")
          {:error, {:provider_sync_failed, reason}}
      end
    end
  end

  def delete(provider_id) when is_binary(provider_id) do
    with {:ok, table} <- table_name() do
      case Dynamo.delete_item(table, %{"id" => provider_id}) |> ExAws.request() do
        {:ok, _response} -> :ok
        {:error, reason} -> {:error, {:provider_sync_failed, reason}}
      end
    end
  end

  def find_by_code(code) do
    with {:ok, table} <- table_name() do
      result =
        Dynamo.query(table,
          index_name: "byAffiliationCode",
          key_condition_expression: "affiliation_code = :code",
          expression_attribute_values: [code: code],
          limit: 1
        )
        |> ExAws.request()

      case result do
        {:ok, %{"Items" => [item | _]}} ->
          Decoder.decode(item)

        {:ok, _} ->
          nil

        {:error, reason} ->
          Logger.warning("[ProviderCatalog] query by code failed: #{inspect(reason)}")
          nil
      end
    else
      _ -> nil
    end
  end

  # The code must not silently attach to a different doctor: only update an
  # existing item when it has no email yet or the email matches.
  defp check_email_conflict(nil, _email), do: :ok
  defp check_email_conflict(_existing, nil), do: :ok
  defp check_email_conflict(_existing, ""), do: :ok

  defp check_email_conflict(existing, email) when is_binary(email) do
    case existing["email"] do
      nil ->
        :ok

      existing_email ->
        if String.downcase(String.trim(existing_email)) == String.downcase(String.trim(email)),
          do: :ok,
          else: {:error, {:affiliation_code_conflict, existing_email}}
    end
  end

  defp provider_fields(attrs, _now) do
    %{
      "full_name" => attrs[:full_name],
      "email" => attrs[:email],
      "affiliation_code" => attrs[:affiliation_code],
      "qualifications" => attrs[:qualifications],
      "clinic_name" => attrs[:clinic_name],
      "website_url" => attrs[:website_url],
      "address" => attrs[:address],
      "city" => attrs[:city],
      "state" => attrs[:state],
      "services" => attrs[:services],
      "category" => attrs[:category],
      "schedule_url" => attrs[:schedule_url],
      "telehealth_available" => attrs[:telehealth_available],
      "phone" => attrs[:phone],
      "profile_img" => attrs[:profile_img] || "NO"
    }
  end

  defp reject_nil(item) do
    item
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp table_name do
    case Application.get_env(:firmtech_api, :provider_table) do
      table when is_binary(table) and table != "" ->
        {:ok, table}

      _ ->
        {:error, :provider_table_not_configured}
    end
  end
end
