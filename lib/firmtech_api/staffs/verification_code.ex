defmodule FirmtechApi.Staffs.VerificationCode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "verification_codes" do
    field :firebase_uid, :string
    field :code, :string
    field :expires_at, :utc_datetime

    timestamps()
  end

  def changeset(verification_code, attrs) do
    verification_code
    |> cast(attrs, [:firebase_uid, :code, :expires_at])
    |> validate_required([:firebase_uid, :code, :expires_at])
    |> unique_constraint(:firebase_uid)
  end
end
