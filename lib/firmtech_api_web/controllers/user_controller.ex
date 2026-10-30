defmodule FirmtechApiWeb.UserController do
  use FirmtechApiWeb, :controller

  alias FirmtechApi.Users
  alias FirmtechApi.Users.User
  alias ExFirebaseAuth.Token
  alias FirmtechApi.Records
  alias FirmtechApi.Users.ExcelExporter
  alias FirmtechApi.Workers.ExportWorker

  action_fallback FirmtechApiWeb.FallbackController

  def index(conn, params) do
    case Users.list_by_user(params, conn.assigns.current_staff) do
      {:ok, {users, meta}} ->
        render(conn, :index, meta: meta, users: users)

      {:error, %Flop.Meta{} = meta} ->
        # Convert Flop errors to a JSON-serializable format
        errors = format_flop_errors(meta.errors)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid query parameters", details: errors})
    end
  end

  defp format_flop_errors(errors) when is_list(errors) do
    Enum.map(errors, fn
      {key, value} when is_tuple(value) ->
        {to_string(key), format_flop_errors(value)}

      {key, value} ->
        {to_string(key), format_error_value(value)}

      other ->
        format_error_value(other)
    end)
    |> Enum.into(%{})
  end

  defp format_flop_errors(errors) when is_tuple(errors) do
    Tuple.to_list(errors)
    |> Enum.map(&format_error_value/1)
  end

  defp format_flop_errors(other), do: format_error_value(other)

  defp format_error_value(value) when is_binary(value), do: value
  defp format_error_value(value) when is_atom(value), do: to_string(value)
  defp format_error_value(value) when is_list(value), do: Enum.map(value, &format_error_value/1)
  defp format_error_value(value) when is_tuple(value), do: format_flop_errors(value)
  defp format_error_value(value) when is_map(value), do: format_flop_errors(value)
  defp format_error_value(value), do: inspect(value)

  def show(conn, %{"id" => id}) do
    try do
      user = Users.get_with_latest_performance_data!(id, conn.assigns.current_staff)
      render(conn, :show, user: user)
    rescue
      Ecto.NoResultsError -> {:error, :forbidden}
    end
  end

  # def create(conn, %{"staff" => staff_params}) do
  #   with {:ok, %Staff{} = staff} <- Staffs.create_staff(staff_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", ~p"/api/staffs/#{staff}")
  #     |> render(:show, staff: staff)
  #   end
  # end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Users.get!(id, conn.assigns.current_staff)

    with {:ok, %User{} = user} <- Users.update(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  @spec unaffiliate_by_staff(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def unaffiliate_by_staff(conn, %{"id" => id}) do
    try do
      user = Users.get!(id, conn.assigns.current_staff)

      with {_count, _users} <- Users.unaffiliate_by_staff(conn.assigns.current_staff, user) do
        json(conn, %{success: true})
      else
        _ ->
          json(conn, %{success: false})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})
    end
  end

  def statistics(conn, %{"id" => id, "from" => from, "to" => to, "utc_offset" => utc_offset}) do
    case Users.get!(id, conn.assigns.current_staff) do
      %FirmtechApi.Users.User{} = user ->
        data = FirmtechApi.PerformanceDatas.RangeStats.compute(user.id, from, to, utc_offset)

        json(conn, %{success: true, data: data})

      {:error, _} ->
        {:error, :forbidden}
    end
  end

  def export(conn, %{"id" => id, "from" => from, "to" => to, "utc_offset" => utc_offset} = params) do
    current_staff = conn.assigns.current_staff

    Oban.insert(
      FirmtechApi.Workers.ExportWorker.new(%{
        "current_staff_id" => current_staff.id,
        "user_id" => id,
        "from" => from,
        "to" => to,
        "utc_offset" => utc_offset
      })
    )

    json(conn |> put_status(:created), %{
      success: true,
      message: "Export started. Staff will receive an email shortly."
    })
  end

  def range_data(conn, %{"id" => id, "from" => from, "to" => to}) do
    # utc_offset is optional, only if provided, add it to the params
    utc_offset = conn.params["utc_offset"] || nil

    params = %{
      "context" => %{
        "user_id" => id
      },
      "params" => %{
        "querystring" => %{
          "dashboard" => true,
          "from" => from,
          "to" => to
        }
      }
    }

    params =
      if utc_offset do
        put_in(params["params"]["querystring"]["utc_offset"], utc_offset)
      else
        params
      end

    case Users.get!(id, conn.assigns.current_staff) do
      %FirmtechApi.Users.User{} = _user ->
        case AwsLambda.invoke_sync(
               "amplify-firmtechbackendgen-rangeDatalambda0A36F76C-Q04nzokDriAi",
               params,
               "us-east-1"
             ) do
          {:ok, response} ->
            json(conn, %{success: true, data: response["dataRows"]})

          {:error, reason} ->
            json(conn, %{success: false, error: inspect(reason)})
        end

      {:error, _} ->
        {:error, :forbidden}
    end
  end

  # def delete(conn, %{"id" => id}) do
  #   staff = Staffs.get_staff!(id)

  #   with {:ok, %Staff{}} <- Staffs.delete_staff(staff) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
