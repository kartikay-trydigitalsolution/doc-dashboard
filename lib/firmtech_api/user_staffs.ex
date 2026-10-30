defmodule FirmtechApi.UserStaffs do
  @moduledoc """
  The UserStaffs context.
  """

  import Ecto.Query, warn: false
  alias FirmtechApi.Repo

  alias FirmtechApi.UserStaffs.UserStaff

  @doc """
  Returns the list of user_staffs.

  ## Examples

      iex> list_user_staffs()
      [%UserStaff{}, ...]

  """
  def list_user_staffs do
    Repo.all(UserStaff)
  end

  @doc """
  Gets a single user_staff.

  Raises `Ecto.NoResultsError` if the User staff does not exist.

  ## Examples

      iex> get_user_staff!(123)
      %UserStaff{}

      iex> get_user_staff!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_staff!(id), do: Repo.get!(UserStaff, id)

  @doc """
  Creates a user_staff.

  ## Examples

      iex> create_user_staff(%{field: value})
      {:ok, %UserStaff{}}

      iex> create_user_staff(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_staff(attrs \\ %{}) do
    %UserStaff{}
    |> UserStaff.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_staff.

  ## Examples

      iex> update_user_staff(user_staff, %{field: new_value})
      {:ok, %UserStaff{}}

      iex> update_user_staff(user_staff, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_staff(%UserStaff{} = user_staff, attrs) do
    user_staff
    |> UserStaff.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_staff.

  ## Examples

      iex> delete_user_staff(user_staff)
      {:ok, %UserStaff{}}

      iex> delete_user_staff(user_staff)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_staff(%UserStaff{} = user_staff) do
    Repo.delete(user_staff)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_staff changes.

  ## Examples

      iex> change_user_staff(user_staff)
      %Ecto.Changeset{data: %UserStaff{}}

  """
  def change_user_staff(%UserStaff{} = user_staff, attrs \\ %{}) do
    UserStaff.changeset(user_staff, attrs)
  end

  def update_or_create_user_staff(%{
        aws_user_uid: aws_user_uid,
        staff_id: staff_id,
        action: action
      }) do
    case Repo.get_by(UserStaff, user_id: aws_user_uid) do
      nil ->
        %UserStaff{}
        |> UserStaff.changeset(%{user_id: aws_user_uid, staff_id: staff_id, status: action})
        |> Repo.insert()

      user_staff ->
        user_staff
        |> UserStaff.changeset(%{user_id: aws_user_uid, staff_id: staff_id, status: action})
        |> Repo.update()
    end
  end
end
