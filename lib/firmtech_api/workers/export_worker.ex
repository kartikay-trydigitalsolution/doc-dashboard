defmodule FirmtechApi.Workers.ExportWorker do
  use Oban.Worker, queue: :default

  alias FirmtechApi.Users

  @impl Oban.Worker
  def perform(%Oban.Job{
    args: %{
      "current_staff_id" => staff_id,
      "user_id" => user_id,
      "from" => from,
      "to" => to,
      "utc_offset" => utc_offset
    }
  }) do

    current_staff = FirmtechApi.Staffs.get_staff!(staff_id)
    user = FirmtechApi.Users.get!(user_id, current_staff)

    user_performance_data =
      FirmtechApi.PerformanceDatas.RangeStats.compute(user_id, from, to, utc_offset)[
        "performance_data"
      ]


     # Calculate start and end of day in UTC, then apply utc_offset (in minutes)
     utc_offset = String.to_integer(utc_offset || "0")
     from_date = from <> "T00:00:00.000Z"
     to_date = to <> "T23:59:59.999Z"

     {:ok, from_dt, _} = DateTime.from_iso8601(from_date)
     {:ok, to_dt, _} = DateTime.from_iso8601(to_date)

     # Apply utc_offset (in minutes) to the datetimes
     from_dt = DateTime.add(from_dt, -utc_offset * 60, :second)
     to_dt = DateTime.add(to_dt, -utc_offset * 60, :second)



    # 3. Fetch records
    processed_params = %{
      "filters" => %{
        "0" => %{"field" => "started_at", "op" => ">=", "value" => DateTime.to_iso8601(from_dt)},
        "1" => %{"field" => "started_at", "op" => "<=", "value" => DateTime.to_iso8601(to_dt)}
      },
      "limit" => "100",
      "offset" => "0",
      "userId" => user_id
    }
    {:ok, {records, _meta}} = FirmtechApi.Records.list_by_user(processed_params, current_staff)

    # 4. Generate Excel file
    {:ok, file_path} = FirmtechApi.Users.ExcelExporter.export(
      user,
      user_performance_data || %{},
      records,
      from,
      to
    )

    # 5. Send email
    full_name = "#{user.first_name} #{user.last_name}"
    FirmtechApi.Emails.send_excel_export(current_staff.email, file_path, full_name, from, to)
    :ok
  end
end
