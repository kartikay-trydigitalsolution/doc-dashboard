defmodule FirmtechApi.Aws.CognitoAuth do
  @moduledoc """
  Module for verifying and decoding AWS Cognito JWT tokens.
  """

  require Logger

  # JWKS cache duration in milliseconds (1 hour by default)
  @jwks_cache_ttl 3_600_000

  @doc """
  Verify and decode a Cognito JWT token.

  ## Parameters
    - token: The JWT token string
    - region: AWS region (e.g., "us-east-1")
    - user_pool_id: Cognito user pool ID

  ## Returns
    - {:ok, claims} - The decoded token claims
    - {:error, reason} - Error with reason
  """
  def verify_token(token, region, user_pool_id) do
    with {:ok, jwks} <- get_cognito_jwks(region, user_pool_id),
         {:ok, kid} <- get_token_kid(token),
         {:ok, public_key} <- get_public_key(jwks, kid),
         {:ok, claims} <- verify_and_decode(token, public_key) do
      {:ok, claims}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get a specific field from a verified token.

  ## Parameters
    - token: The JWT token string
    - field: The field name to extract
    - region: AWS region (e.g., "us-east-1")
    - user_pool_id: Cognito user pool ID

  ## Returns
    - {:ok, value} - The field value
    - {:error, reason} - Error with reason
  """
  def get_field_from_token(token, field, region, user_pool_id) do
    case verify_token(token, region, user_pool_id) do
      {:ok, claims} when is_map(claims) ->
        case Map.get(claims, field) do
          nil -> {:error, "Field #{field} not found in token"}
          value -> {:ok, value}
        end

      error ->
        error
    end
  end

  # Get the token's Key ID (kid) from the header
  defp get_token_kid(token) do
    with [header, _, _] <- String.split(token, "."),
         {:ok, decoded} <-
           Base.url_decode64(
             header <> String.duplicate("=", rem(4 - rem(byte_size(header), 4), 4))
           ),
         {:ok, header_json} <- Jason.decode(decoded),
         %{"kid" => kid} <- header_json do
      {:ok, kid}
    else
      _ -> {:error, "Failed to extract kid from token header"}
    end
  end

  # Get the Cognito JWKS (JSON Web Key Set)
  defp get_cognito_jwks(region, user_pool_id) do
    jwks_url = "https://cognito-idp.#{region}.amazonaws.com/#{user_pool_id}/.well-known/jwks.json"

    # Use a caching mechanism here to avoid frequent HTTP requests
    # This example uses a simple GenServer-based cache (implementation not shown)
    case FirmtechApi.Cache.get({:cognito_jwks, user_pool_id}) do
      nil ->
        # If not in cache, fetch from Cognito
        case HTTPoison.get(jwks_url) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            case Jason.decode(body) do
              {:ok, jwks} ->
                # Cache the JWKS for future use
                FirmtechApi.Cache.put({:cognito_jwks, user_pool_id}, jwks, @jwks_cache_ttl)
                {:ok, jwks}

              error ->
                Logger.error("Failed to decode JWKS: #{inspect(error)}")
                {:error, "Failed to decode JWKS"}
            end

          error ->
            Logger.error("Failed to fetch JWKS: #{inspect(error)}")
            {:error, "Failed to fetch JWKS"}
        end

      jwks ->
        # Return cached JWKS
        {:ok, jwks}
    end
  end

  # Find the matching public key from JWKS using the kid
  defp get_public_key(jwks, kid) do
    case Enum.find(jwks["keys"], fn key -> key["kid"] == kid end) do
      nil ->
        {:error, "No matching key found for kid: #{kid}"}

      key ->
        # Convert JWK to PEM format
        case JOSE.JWK.from(key) |> JOSE.JWK.to_pem() do
          {_, pem_binary} -> {:ok, pem_binary}
          _ -> {:error, "Failed to convert JWK to PEM"}
        end
    end
  end

  # Verify and decode the token using the public key
  defp verify_and_decode(token, public_key) do
    case Joken.verify(token, Joken.Signer.create("RS256", %{"pem" => public_key})) do
      {:ok, claims} ->
        # Additional verification steps (issuer, token expiration, etc.)
        verify_claims(claims)

      {:error, reason} ->
        Logger.error("Token verification failed: #{inspect(reason)}")
        {:error, "Token verification failed"}
    end
  end

  # Verify token claims (issuer, expiration, etc.)
  defp verify_claims(claims) do
    cond do
      # Check if token is expired
      Map.get(claims, "exp", 0) < DateTime.utc_now() |> DateTime.to_unix() ->
        {:error, "Token expired"}

      # Verify the token was issued by the right Cognito user pool
      # This should match your Cognito user pool's issuer
      # !String.starts_with?(Map.get(claims, "iss", ""), "https://cognito-idp.#{region}.amazonaws.com/#{user_pool_id}") ->
      #   {:error, "Invalid token issuer"}

      # Add any additional verification rules here

      true ->
        {:ok, claims}
    end
  end
end

# Simple in-memory cache implementation
# In a production environment, consider using a more robust caching solution
defmodule FirmtechApi.Cache do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value, ttl \\ :infinity) do
    GenServer.cast(__MODULE__, {:put, key, value, ttl})
  end

  # GenServer callbacks

  def handle_call({:get, key}, _from, state) do
    case Map.get(state, key) do
      {value, expiry} ->
        if expiry == :infinity || expiry > System.monotonic_time(:millisecond) do
          {:reply, value, state}
        else
          {:reply, nil, Map.delete(state, key)}
        end

      nil ->
        {:reply, nil, state}
    end
  end

  def handle_cast({:put, key, value, :infinity}, state) do
    {:noreply, Map.put(state, key, {value, :infinity})}
  end

  def handle_cast({:put, key, value, ttl}, state) do
    expiry = System.monotonic_time(:millisecond) + ttl
    {:noreply, Map.put(state, key, {value, expiry})}
  end
end
