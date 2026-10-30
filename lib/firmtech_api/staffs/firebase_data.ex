defmodule FirmtechApi.Staffs.FirebaseData do
  @derive {Jason.Encoder, only: [:firebase_uid, :email, :fb_name, :fb_profile_picture, :fb_meta]}

  defstruct [
    :firebase_uid,
    :email,
    :fb_name,
    :fb_profile_picture,
    :fb_meta
  ]

  @type t :: %__MODULE__{
          firebase_uid: String.t(),
          email: String.t(),
          fb_name: String.t() | nil,
          fb_profile_picture: String.t() | nil,
          fb_meta: map() | nil
        }
end
