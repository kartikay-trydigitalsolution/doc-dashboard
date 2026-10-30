defmodule FirmtechApi.Users do
  alias FirmtechApi.Repo
  alias FirmtechApi.Users.User
  alias FirmtechApi.Staffs.Staff
  alias FirmtechApi.UserStaffs.UserStaff
  alias FirmtechApi.PerformanceDatas.PerformanceData
  import Ecto.Query, warn: false

  @spec list_by_user(map, Staff.t()) ::
          {:ok, {[User.t()], Flop.Meta.t()}} | {:error, Flop.Meta.t()}
  def list_by_user(params \\ %{}, current_staff) do
    # Normalize params: ensure string keys and convert single string values to arrays for Flop
    params =
      params
      |> stringify_param_keys()
      |> normalize_flop_params()

    # Check if sorting by efs or age
    order_by_list = params |> Map.get("order_by", []) |> List.wrap()
    order_directions_list = params |> Map.get("order_directions", ["asc"]) |> List.wrap()
    order_by = (order_by_list |> List.first() || "") |> to_string()
    order_directions = (order_directions_list |> List.first() || "asc") |> to_string()
    sorting_by_efs = String.contains?(order_by, "efs")
    sorting_by_age = String.contains?(order_by, "age")

    # Remove efs or age from params for Flop validation, we'll handle them manually
    flop_params =
      if sorting_by_efs or sorting_by_age do
        params
        |> Map.delete("order_by")
        |> Map.delete("order_directions")
      else
        params
      end

    query =
      User
      |> scope_this_staff(current_staff)
      |> join_latest_performance_data(sorting_by_efs)
      |> apply_efs_sorting(sorting_by_efs, order_directions)
      |> apply_age_sorting(sorting_by_age, order_directions)
      |> preload_latest_performance_data()

    case Flop.validate_and_run(query, flop_params, for: User) do
      {:ok, {users, meta}} ->
        users_with_latest_performance_data =
          users
          |> Enum.map(&add_latest_performance_data/1)
          |> FirmtechApi.Users.DynamoSync.enrich_users()

        {:ok, {users_with_latest_performance_data, meta}}

      error ->
        error
    end
  end

  defp normalize_flop_params(params) do
    params
    |> normalize_order_by()
    |> normalize_order_directions()
  end

  defp stringify_param_keys(params) when is_map(params) do
    Enum.reduce(params, %{}, fn
      {key, value}, acc when is_atom(key) ->
        Map.put(acc, Atom.to_string(key), value)

      {key, value}, acc when is_binary(key) ->
        Map.put(acc, key, value)

      {key, value}, acc ->
        Map.put(acc, to_string(key), value)
    end)
  end

  defp normalize_order_by(params) do
    case Map.get(params, "order_by") do
      nil ->
        params

      value when is_binary(value) ->
        # Convert single string to array
        Map.put(params, "order_by", [value])

      value when is_list(value) ->
        # Already an array
        params

      _ ->
        params
    end
  end

  defp normalize_order_directions(params) do
    case Map.get(params, "order_directions") do
      nil ->
        params

      value when is_binary(value) ->
        # Convert single string to array
        Map.put(params, "order_directions", [value])

      value when is_list(value) ->
        # Already an array
        params

      _ ->
        params
    end
  end

  defp scope_this_staff(query, %Staff{id: staff_id}) do
    # where there is a UserStaff with staff_id and the User
    # where the UserStaff is approved
    query
    |> join(:inner, [u], us in UserStaff, on: u.id == us.user_id)
    |> where([u, us], us.staff_id == ^staff_id)
    |> where([u, us], us.status == :affiliated)
  end

  defp join_latest_performance_data(query, false), do: query

  defp join_latest_performance_data(query, true) do
    # Get the max updated_at per user first
    max_updated_subquery =
      from(pd in PerformanceData,
        group_by: pd.user_id,
        select: %{
          user_id: pd.user_id,
          max_updated_at: max(pd.updated_at)
        }
      )

    # Then join back to get the erectile_fitness_score for the latest record
    latest_pd_subquery =
      from(pd in PerformanceData,
        join: max_pd in subquery(max_updated_subquery),
        on: pd.user_id == max_pd.user_id and pd.updated_at == max_pd.max_updated_at,
        select: %{
          user_id: pd.user_id,
          erectile_fitness_score: pd.erectile_fitness_score
        }
      )

    query
    |> join(:left, [u, us], pd in subquery(latest_pd_subquery), on: u.id == pd.user_id)
  end

  defp apply_efs_sorting(query, false, _), do: query

  defp apply_efs_sorting(query, true, direction) do
    case String.downcase(direction) do
      "desc" ->
        query |> order_by([u, us, pd], desc: pd.erectile_fitness_score)

      _ ->
        query |> order_by([u, us, pd], asc: pd.erectile_fitness_score)
    end
  end

  defp apply_age_sorting(query, false, _), do: query

  defp apply_age_sorting(query, true, direction) do
    # Age is calculated from date_of_birth
    # To sort by age ascending: sort by date_of_birth descending (older = higher age)
    # To sort by age descending: sort by date_of_birth ascending (newer = lower age)
    case String.downcase(direction) do
      "desc" ->
        # Age descending = date_of_birth ascending (newer dates first = younger users first)
        query |> order_by([u, us], asc_nulls_last: u.date_of_birth)

      _ ->
        # Age ascending = date_of_birth descending (older dates first = older users first)
        query |> order_by([u, us], desc_nulls_last: u.date_of_birth)
    end
  end

  defp preload_latest_performance_data(query) do
    # Use a simple preload approach - this will load all performance data
    # and we'll handle getting the latest one in the application layer
    query
    |> preload(:performance_datas)
  end

  defp add_latest_performance_data(%User{} = user) do
    latest_performance_data =
      user.performance_datas
      |> Enum.sort_by(& &1.updated_at, {:desc, NaiveDateTime})
      |> List.first()

    %{user | latest_performance_data: latest_performance_data}
  end

  @doc """
  Checks if a staff member has access to a specific user without enriching from DynamoDB.
  """
  def has_access?(id, %Staff{} = current_staff) do
    User
    |> scope_this_staff(current_staff)
    |> where([u], u.id == ^id)
    |> Repo.exists?()
  end

  @doc """
  Gets a single user by ID.
  Raises `FirmtechApi.Users.UserNotFoundError` if the User does not exist or is not accessible.
  """
  def get!(id, current_staff) do
    case User
         |> scope_this_staff(current_staff)
         |> Repo.get(id) do
      nil -> {:error, :not_found}
      user -> FirmtechApi.Users.DynamoSync.enrich_user(user)
    end
  end

  @doc """
  Gets a single user by ID.
  Returns `nil` if the User does not exist.
  """
  def get(id) do
    case Repo.get(User, id) do
      nil -> nil
      user -> FirmtechApi.Users.DynamoSync.enrich_user(user)
    end
  end

  def get_with_latest_performance_data!(id, current_staff) do
    User
    |> scope_this_staff(current_staff)
    |> preload(:performance_datas)
    |> Repo.get!(id)
    |> add_latest_performance_data()
    |> FirmtechApi.Users.DynamoSync.enrich_user()
  end

  @doc """
  Gets a user by specific attribute.
  """
  def get_by(attrs) when is_list(attrs) or is_map(attrs) do
    Repo.get_by(User, attrs)
  end

  @doc """
  Lists all active users.
  """
  def list_active do
    User
    |> where([u], u.status == :active)
    |> Repo.all()
  end

  @doc """
  Creates a user.
  """
  def create(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft deletes a user by setting deleted_at timestamp.
  """
  def soft_delete(%User{} = user) do
    user
    |> User.changeset(%{deleted_at: NaiveDateTime.utc_now(), status: :deleted})
    |> Repo.update()
  end

  @doc """
  Hard deletes a user from the database.
  """
  def delete(%User{} = user) do
    Repo.delete(user)
  end

  def unaffiliate_by_staff(%Staff{} = staff, %User{} = user) do
    UserStaff
    |> where([us], us.user_id == ^user.id)
    |> where([us], us.staff_id == ^staff.id)
    |> Repo.delete_all()
  end

  defmodule UserNotFoundError do
    defexception message: "User not found or not accessible"
  end
end
