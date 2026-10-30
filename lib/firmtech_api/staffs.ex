defmodule FirmtechApi.Staffs do
  alias FirmtechApi.Staffs.FirebaseData
  alias FirmtechApi.Staffs.Staff
  alias FirmtechApi.UserStaffs
  alias FirmtechApi.UserStaffs.UserStaff
  require Logger

  @moduledoc """
  The Staffs context.
  """

  import Ecto.Query, warn: false
  alias FirmtechApi.Repo
  alias Ecto.Multi
  alias FirmtechApi.FirebaseClient
  alias FirmtechApi.ProviderCatalog

  alias FirmtechApi.Staffs.Staff

  @doc """
  Returns the list of staffs.

  ## Examples

      iex> list_staffs()
      [%Staff{}, ...]

  """
  def list_staffs do
    Repo.all(Staff)
  end

  @doc """
  Gets a single staff.

  Raises `Ecto.NoResultsError` if the Staff does not exist.

  ## Examples

      iex> get_staff!(123)
      %Staff{}

      iex> get_staff!(456)
      ** (Ecto.NoResultsError)

  """
  def get_staff!(id), do: Repo.get!(Staff, id)

  @doc """
  Creates a staff.

  ## Examples

      iex> create_staff(%{field: value})
      {:ok, %Staff{}}

      iex> create_staff(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_staff(attrs \\ %{}) do
    %Staff{}
    |> Staff.changeset(attrs)
    |> Repo.insert()
  end

  @affiliation_code_charset ~c"ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

  @doc """
  Creates a doctor that can log in to the dashboard and be found in the app.

  It provisions three places, all keyed by the same `affiliation_code`:

    * Firebase Auth user (email + password)
    * DynamoDB `Provider` row (the app-facing provider catalog/profile)
    * PostgreSQL `staffs` row (dashboard account + patient link)

  The `affiliation_code` is the code the patient types in the app to link with
  this doctor; it lives in `staffs.affiliation_code` (unique) and is matched
  case-insensitively.

  Returns `{:ok, staff, temporary_password, provider_id}`. The password is only
  returned when it was generated here (the caller did not pass one).
  """
  def create_doctor(attrs) do
    email = attrs[:email]
    category = attrs[:category] || :doctor
    provider_category = normalize_provider_category(attrs[:provider_category])

    with :ok <- validate_doctor_attrs(email, category),
         :ok <- validate_provider_category(provider_category),
         {:ok, password, generated?} <- resolve_password(attrs[:password]) do
      code = attrs[:affiliation_code] || unique_affiliation_code()

      case FirebaseClient.create_user(
             email,
             password,
             display_name(attrs[:first_name], attrs[:last_name])
           ) do
        {:ok, firebase_uid} ->
          create_doctor_records(
            attrs,
            firebase_uid,
            code,
            provider_category,
            password,
            generated?
          )

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp create_doctor_records(attrs, firebase_uid, code, provider_category, password, generated?) do
    provider_attrs = %{
      affiliation_code: code,
      email: attrs[:email],
      full_name:
        display_name(attrs[:first_name], attrs[:last_name]) || attrs[:full_name] || attrs[:email],
      qualifications: attrs[:qualifications],
      clinic_name: attrs[:clinic_name],
      website_url: attrs[:website_url],
      address: attrs[:address],
      city: attrs[:city],
      state: attrs[:state],
      services: normalize_services(attrs[:services]),
      category: provider_category,
      schedule_url: attrs[:schedule_url],
      telehealth_available: attrs[:telehealth_available],
      phone: attrs[:phone],
      profile_img: attrs[:profile_img]
    }

    case ProviderCatalog.upsert(provider_attrs) do
      {:ok, provider_id, provider_created?} ->
        insert_doctor_records(
          attrs,
          firebase_uid,
          code,
          provider_id,
          provider_created?,
          password,
          generated?
        )

      {:error, reason} ->
        Logger.error(
          "Doctor create: provider sync failed, rolling back Firebase user #{firebase_uid}: #{inspect(reason)}"
        )

        FirebaseClient.delete_user(firebase_uid)
        {:error, reason}
    end
  end

  defp insert_doctor_records(
         attrs,
         firebase_uid,
         code,
         provider_id,
         provider_created?,
         password,
         generated?
       ) do
    result =
      insert_doctor(%{
        firebase_uid: firebase_uid,
        email: attrs[:email],
        first_name: attrs[:first_name],
        last_name: attrs[:last_name],
        category: attrs[:category] || :doctor,
        status: :active,
        affiliation_code: code
      })

    case result do
      {:ok, staff} ->
        set_api_staff_id(firebase_uid, staff.id)
        {:ok, staff, if(generated?, do: password, else: nil), provider_id}

      {:error, changeset} ->
        Logger.error("Doctor create: staff insert failed: #{inspect(changeset.errors)}")
        FirebaseClient.delete_user(firebase_uid)
        if provider_created?, do: ProviderCatalog.delete(provider_id)
        {:error, changeset}
    end
  end

  @doc """
  Generates an affiliation code, e.g. `DR-7KQ2XM`.
  """
  def generate_affiliation_code(length \\ 6) do
    body = for _ <- 1..length, into: "", do: <<Enum.random(@affiliation_code_charset)>>
    "DR-" <> body
  end

  defp insert_doctor(attrs) do
    code = attrs[:affiliation_code] || unique_affiliation_code()

    %Staff{}
    |> Staff.changeset(Map.put(attrs, :affiliation_code, code))
    |> Repo.insert()
  end

  defp unique_affiliation_code(attempts \\ 5) do
    code = generate_affiliation_code()

    cond do
      attempts <= 0 ->
        code

      is_nil(Repo.get_by(Staff, affiliation_code: code)) ->
        code

      true ->
        unique_affiliation_code(attempts - 1)
    end
  end

  defp validate_doctor_attrs(nil, _category), do: {:error, :email_required}
  defp validate_doctor_attrs("", _category), do: {:error, :email_required}

  defp validate_doctor_attrs(_email, category) when category in [:admin, :manager, :doctor],
    do: :ok

  defp validate_doctor_attrs(_email, _category), do: {:error, :invalid_category}

  defp normalize_services(nil), do: nil

  defp normalize_services(services) when is_list(services) do
    services
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_services(services) when is_binary(services) do
    services
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> nil
      list -> list
    end
  end

  defp normalize_services(_services), do: nil

  defp normalize_provider_category(nil), do: nil
  defp normalize_provider_category(""), do: nil

  defp normalize_provider_category(value) when is_binary(value),
    do: String.upcase(String.trim(value))

  defp normalize_provider_category(value), do: value

  defp validate_provider_category(nil), do: :ok

  defp validate_provider_category(value) when is_binary(value) do
    if value in ProviderCatalog.category_values(),
      do: :ok,
      else: {:error, :invalid_provider_category}
  end

  defp validate_provider_category(_value), do: {:error, :invalid_provider_category}

  defp resolve_password(nil), do: {:ok, generated_password(), true}
  defp resolve_password(""), do: {:ok, generated_password(), true}
  defp resolve_password(password) when is_binary(password), do: {:ok, password, false}

  defp generated_password do
    12
    |> :crypto.strong_rand_bytes()
    |> Base.encode32(padding: false)
    |> binary_part(0, 12)
  end

  defp display_name(nil, _last_name), do: nil
  defp display_name("", _last_name), do: nil
  defp display_name(first_name, nil), do: first_name
  defp display_name(first_name, ""), do: first_name
  defp display_name(first_name, last_name), do: "#{first_name} #{last_name}"

  defp set_api_staff_id(firebase_uid, staff_id) do
    case FirebaseClient.set_custom_claim(firebase_uid, %{api_staff_id: staff_id}) do
      {:ok, status_code: 200} ->
        :ok

      {:goth_error, reason} ->
        Logger.error("Set api_staff_id ERROR for staff #{staff_id}: #{inspect(reason)}")
        :ok

      error ->
        Logger.error("Set api_staff_id ERROR for staff #{staff_id}: #{inspect(error)}")
        :ok
    end
  end

  @doc """
  Updates a staff.

  ## Examples

      iex> update_staff(staff, %{field: new_value})
      {:ok, %Staff{}}

      iex> update_staff(staff, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_staff(%Staff{} = staff, attrs) do
    staff
    |> Staff.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a staff.

  ## Examples

      iex> delete_staff(staff)
      {:ok, %Staff{}}

      iex> delete_staff(staff)
      {:error, %Ecto.Changeset{}}

  """
  def delete_staff(%Staff{} = staff) do
    Repo.delete(staff)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking staff changes.

  ## Examples

      iex> change_staff(staff)
      %Ecto.Changeset{data: %Staff{}}

  """
  def change_staff(%Staff{} = staff, attrs \\ %{}) do
    Staff.changeset(staff, attrs)
  end

  # def get_staff_by_id_and_firebase_uid!(id, firebase_uid) do
  #   Staff
  #   |> where([u], u.id == ^id and u.firebase_uid == ^firebase_uid)
  #   |> Repo.one()
  # end

  def get_staff_by_firebase_uid!(firebase_uid) do
    get_staff_by_firebase_uid(firebase_uid)
  end

  def get_staff_by_firebase_uid(firebase_uid) do
    Staff
    |> where([u], u.firebase_uid == ^firebase_uid)
    |> Repo.one()
  end

  def get_or_create_staff(
        %FirebaseData{
          firebase_uid: user_id,
          email: _email,
          fb_name: _fb_name,
          fb_profile_picture: _fb_profile_picture,
          fb_meta: _fb_meta
        } = fb_data,
        %{first_name: _first_name, last_name: _last_name} = attrs
      ) do
    Staff
    |> where([u], u.firebase_uid == ^user_id)
    # |> preload([:addresses, :preferred_cuisine_types, [dish_ratings: :dish]])
    |> Repo.one() ||
      logister_user(fb_data, attrs)
  end

  defp logister_user(
         %{
           firebase_uid: user_id,
           email: email,
           fb_name: fb_name,
           fb_profile_picture: fb_profile_picture,
           fb_meta: fb_meta
         } = _params,
         %{first_name: first_name, last_name: last_name} = _attrs
       ) do
    # with
    # {:ok, %NamePartsExtractor{first_name: first_name, last_name: last_name}} <-
    #        NamePartsExtractor.extract(fb_name),
    # TODO: later remove status: :active
    with params <-
           Map.merge(%{}, %{
             first_name: first_name,
             last_name: last_name,
             status: :active,
             firebase_uid: user_id,
             email: email,
             fb_name: fb_name,
             fb_profile_picture: fb_profile_picture,
             fb_meta: fb_meta
           }),
         {:ok, %{staff: staff, set_firebase_claim: _}} <-
           Multi.new()
           |> Multi.insert(:staff, Staff.changeset(%Staff{}, params))
           |> Multi.run(:set_firebase_claim, fn _repo, %{staff: staff} ->
             case FirebaseClient.set_custom_claim(params.firebase_uid, %{
                    api_staff_id: staff.id
                  }) do
               {:ok, status_code: 200} ->
                 Logger.info("Set api_staff_id OK for: #{staff.id}")
                 {:ok, staff}

               {:error, _reason} ->
                 Logger.error("Set api_staff_id ERROR for: #{staff.id}")
                 {:goth_error, "Error in Goth"}

               err ->
                 Logger.error("logister_user ERROR for: #{staff.id}")
                 {:error, err}
             end
           end)
           |> Repo.transaction() do
      IO.puts("IS NEW")

      # Preload some associations after user creation
      # chefi_user =
      #   Repo.preload(chefi_user, [:addresses, :preferred_cuisine_types, [dish_ratings: :dish]])

      %{staff | is_new: true}
    else
      {:error, :chefi_user, changeset, _} ->
        {:error, changeset}

      {:error, :set_firebase_claim, error, _changes} ->
        {:error, error}

      error ->
        # Handle any error from NamePartsExtractor
        {:error, error}
    end
  end

  def get_staff_by_affiliation_code(affiliation_code) do
    Staff
    |> where([u], u.affiliation_code == ^affiliation_code)
    |> Repo.one()
  end

  def affiliate(%{affiliation_code: affiliation_code, aws_user_uid: aws_user_uid, action: action}) do
    IO.puts("affiliate")
    IO.inspect(affiliation_code)
    IO.inspect(aws_user_uid)
    IO.inspect(action)

    with %Staff{} = staff <- get_staff_by_affiliation_code(affiliation_code) do
      UserStaffs.update_or_create_user_staff(%{
        aws_user_uid: aws_user_uid,
        staff_id: staff.id,
        action: action
      })

      {:ok, :affiliated_successfully}
    else
      _ ->
        {:error, "Staff not found"}
    end
  end

  def get_user_staff_by_aws_user_uid(aws_user_uid) do
    # load staff by user_id by way of UserStaffs
    UserStaff
    |> where([u], u.user_id == ^aws_user_uid)
    |> preload([:staff])
    |> Repo.one()
  end
end
