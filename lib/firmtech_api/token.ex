defmodule FirmtechApi.Token do
  @moduledoc """
  Handles generation and verification of application JWT tokens.
  """

  # You should store this in your config
  @signing_salt "your-signing-salt"
  # Token valid for 30 days
  @token_age_secs 30 * 24 * 60 * 60

  @doc """
  Generates a JWT token for a user after they've completed the verification step.
  """
  def generate_user_token(user) do
    Phoenix.Token.sign(
      FirmtechApiWeb.Endpoint,
      @signing_salt,
      %{
        sub: user.id,
        firebase_uid: user.firebase_uid,
        email: user.email
      }
    )
  end

  @doc """
  Verifies a user token.
  Returns {:ok, claims} if valid, or {:error, reason} if invalid.
  """
  def verify_user_token(token) do
    Phoenix.Token.verify(
      FirmtechApiWeb.Endpoint,
      @signing_salt,
      token,
      max_age: @token_age_secs
    )
  end

  @doc """
  An alternative implementation using Joken if you prefer JWT standard tokens
  """
  def generate_jwt_token(user) do
    # Define your claims
    claims = %{
      "sub" => user.id,
      "firebase_uid" => user.firebase_uid,
      "email" => user.email,
      "exp" => DateTime.utc_now() |> DateTime.add(@token_age_secs, :second) |> DateTime.to_unix()
    }

    # You'd need to add the Joken library to your dependencies
    # This is pseudocode that would work with Joken
    FirmtechApi.Token.Signer.sign(claims)
  end

  def verify_jwt_token(token) do
    # Using Joken
    FirmtechApi.Token.Signer.verify(token)
  end
end
