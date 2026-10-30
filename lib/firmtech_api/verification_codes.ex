defmodule FirmtechApi.VerificationCodes do
  @moduledoc """
  Handles generation and verification of email verification codes.
  """

  alias FirmtechApi.Repo
  alias FirmtechApi.Staffs.VerificationCode

  import Ecto.Query, warn: false

  # Code will expire after 15 minutes
  @expiration_time 15 * 60

  @doc """
  Generates a verification code for a user and sends it via email.
  Returns the verification code record.
  """
  def generate_for_user(firebase_uid, email) do
    # NOTE: Temporary hardcoded code — email delivery is not configured yet.
    # TODO: switch back to a random 6-digit code once SES/Gmail email is verified.
    code = "123456"

    # Delete any existing codes for this user
    Repo.delete_all(from v in VerificationCode, where: v.firebase_uid == ^firebase_uid)

    # Create a new verification code record
    {:ok, verification} =
      %VerificationCode{}
      |> VerificationCode.changeset(%{
        firebase_uid: firebase_uid,
        code: code,
        expires_at: DateTime.utc_now() |> DateTime.add(@expiration_time, :second)
      })
      |> Repo.insert()

    # Send email with verification code
    FirmtechApi.Emails.send_verification_code(email, code)

    verification
  end

  @doc """
  Verifies a code provided by a user.
  Returns :ok if valid, or an error tuple if invalid or expired.
  """
  def verify_code(firebase_uid, provided_code) do
    now = DateTime.utc_now()

    case Repo.get_by(VerificationCode, firebase_uid: firebase_uid) do
      nil ->
        {:error, :not_found}

      verification ->
        cond do
          DateTime.compare(verification.expires_at, now) == :lt ->
            {:error, :expired}

          verification.code != provided_code ->
            {:error, :invalid_code}

          true ->
            # Delete the code after successful verification
            Repo.delete(verification)
            :ok
        end
    end
  end
end
