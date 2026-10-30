defmodule FirmtechApi.Staffs.Staff do
  use Ecto.Schema
  import Ecto.Changeset

  alias FirmtechApi.UserStaffs.UserStaff

  @derive {Jason.Encoder,
           only: [
             :id,
             :status,
             :category,
             :firebase_uid,
             :first_name,
             :last_name,
             :email,
             :fb_name,
             :fb_profile_picture,
             :fb_meta,
             :is_new
           ]}

  schema "staffs" do
    field :status, Ecto.Enum, values: StaffStatusEnum.__enum_map__()
    field :category, Ecto.Enum, values: StaffCategoryEnum.__enum_map__()
    field :firebase_uid, :string
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :fb_name, :string
    field :fb_profile_picture, :string
    field :fb_meta, :map
    field :is_new, :boolean, default: false, virtual: true
    field :affiliation_code, :string
    has_many :user_staffs, UserStaff
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(staff, attrs) do
    staff
    |> cast(attrs, [
      :firebase_uid,
      :category,
      :first_name,
      :last_name,
      :email,
      :status,
      :fb_name,
      :fb_profile_picture,
      :fb_meta,
      :affiliation_code,
      :is_new
    ])
    |> validate_required([
      :firebase_uid,
      # :category,
      # :first_name,
      # :last_name,
      :email
      # :status,
      # :fb_name,
      # :fb_profile_picture
    ])
    |> unique_constraint(:affiliation_code, name: "unq_staffs_affiliation_code")
    |> unique_constraint(:firebase_uid, name: "uni_staffs_firebase_uid")
  end
end
