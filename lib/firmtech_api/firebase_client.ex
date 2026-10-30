defmodule FirmtechApi.FirebaseClient do
  require Logger

  def set_custom_claim(firebase_uid, claims) do
    firebase_project_id = Application.get_env(:firmtech_api, :firebase_project_id)

    IO.inspect(firebase_project_id)

    {:ok, token} = Goth.fetch(FirmtechApi.Goth)
    IO.inspect(token)
    url =
      "https://identitytoolkit.googleapis.com/v1/projects/#{firebase_project_id}/accounts:update"

    body = %{
      localId: firebase_uid,
      customAttributes: Jason.encode!(claims)
    }

    headers = [
      {"Authorization", "Bearer #{token.token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, Jason.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        {:ok, status_code: 200}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to set custom claim: #{inspect(reason)}")
        {:goth_error, reason}
    end
  end

  @doc """
  Creates a Firebase Auth user (email + password) with the Admin API and returns
  its `localId`, which is the `firebase_uid` stored in `staffs.firebase_uid`.
  """
  def create_user(email, password, display_name \\ nil) do
    firebase_project_id = Application.get_env(:firmtech_api, :firebase_project_id)

    payload =
      %{email: email, password: password, emailVerified: false}
      |> maybe_put(:displayName, display_name)
      |> Jason.encode!()

    headers = [
      {"Authorization", "Bearer #{goth_token!()}"},
      {"Content-Type", "application/json"}
    ]

    url = "https://identitytoolkit.googleapis.com/v1/projects/#{firebase_project_id}/accounts"

    case HTTPoison.post(url, payload, headers) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}}
      when status_code in 200..299 ->
        case decode_body(body) do
          %{"localId" => local_id} -> {:ok, local_id}
          _ -> {:error, {:firebase_error, status_code, body}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {:firebase_error, status_code, firebase_error_message(body)}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to create firebase user: #{inspect(reason)}")
        {:error, {:firebase_unreachable, reason}}
    end
  end

  @doc """
  Deletes a Firebase Auth user by its `localId` (the `firebase_uid`).
  """
  def delete_user(firebase_uid) do
    firebase_project_id = Application.get_env(:firmtech_api, :firebase_project_id)

    payload = Jason.encode!(%{localId: firebase_uid})

    headers = [
      {"Authorization", "Bearer #{goth_token!()}"},
      {"Content-Type", "application/json"}
    ]

    url = "https://identitytoolkit.googleapis.com/v1/projects/#{firebase_project_id}/accounts:delete"

    case HTTPoison.post(url, payload, headers) do
      {:ok, %HTTPoison.Response{status_code: status_code}} when status_code in 200..299 ->
        {:ok, status_code: status_code}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {:firebase_error, status_code, firebase_error_message(body)}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:firebase_unreachable, reason}}
    end
  end

  defp goth_token! do
    case Goth.fetch(FirmtechApi.Goth) do
      {:ok, token} ->
        token.token

      {:error, reason} ->
        Logger.error("Failed to fetch goth token: #{inspect(reason)}")
        raise "Unable to fetch google access token: #{inspect(reason)}"
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp firebase_error_message(body) do
    case decode_body(body) do
      %{"error" => %{"message" => message}} -> message
      _ -> body
    end
  end

  # The identity toolkit sometimes answers with the payload encoded twice.
  defp decode_body(body) do
    case Jason.decode(body) do
      {:ok, %{} = map} ->
        map

      {:ok, inner} when is_binary(inner) ->
        case Jason.decode(inner) do
          {:ok, %{} = map} -> map
          _ -> %{}
        end

      _ ->
        %{}
    end
  end
end
