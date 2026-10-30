defmodule FirmtechApi.Aws.AwsActions do
  require Logger

  # export AWS_COGNITO_IDENTITY_POOL_ID="us-east-1:a2d7665a-34b2-404c-9030-"
  # export AWS_COGNITO_USER_POOL_ID="us--1_cG7kXUlGD"
  # export AWS_COGNITO_CLIENT_ID=""

  def authenticate(token) do
    # Your AWS region
    region = System.get_env("AWS_REGION")
    # Your Cognito User Pool ID
    user_pool_id = System.get_env("AWS_COGNITO_USER_POOL_ID")

    case FirmtechApi.Aws.CognitoAuth.verify_token(token, region, user_pool_id) do
      {:ok, claims} ->
        # Token is valid, use the claims
        Logger.info("User authenticated: #{claims["sub"]}")
        {:ok, claims}

      {:error, reason} ->
        # Token is invalid
        Logger.error("Authentication failed: #{reason}")
        {:error, :unauthorized}
    end
  end
end
