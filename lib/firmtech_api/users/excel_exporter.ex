defmodule FirmtechApi.Users.ExcelExporter do
  alias Exceed.Workbook
  alias Exceed.Worksheet

  def export(user, performance_data, records, from_date, to_date) do
    # Patient Profile Sheet
    patient_profile_rows = [
      ["First Name", dash(user.first_name)],
      ["Last Name", dash(user.last_name)],
      ["Email", ""],
      ["Age", dash(format_decimal(calc_age(user.date_of_birth)))],
      ["Weight", dash(format_decimal(user.weight) <> " " <> to_string(user.weight_unit))],
      ["Height", dash(format_decimal(user.height) <> " " <> to_string(user.height_unit))],
      ["Body Mass Index (BMI)", dash(format_decimal(user.bmi))],
      ["Sexual Health Inventory for Men (SHIM)", dash(format_decimal(user.shim_score))],
      ["Diagnosed Erectile Dysfunction", dash(user.ed_diagnosis)],
      ["Is the patient concerned about possible ED?", dash(user.ed_concern)],
      ["Does the patient climax?", dash(user.uf_climax)],
      ["Diagnosed Hypertension", dash(user.hypertension)],
      ["Diagnosed Diabetes", dash(user.diabetes)],
      [],
      [
        "Erectile Fitness Score (EFS)",
        dash(format_decimal(performance_data["erectile_fitness_score"]))
      ],
      [
        "Avg. Firmness Score - Nocturnal",
        dash(format_decimal(performance_data["avg_firmness_score__nocturnal"]))
      ],
      [
        "Avg. Firmness Score - Sex & Solo",
        dash(format_decimal(performance_data["avg_firmness_score__sex_solo"]))
      ],
      [
        "Avg. Nocturnal Erections Per Night - Count",
        dash(format_decimal(performance_data["avg_count__nocturnal"]))
      ],
      [
        "Avg. Nocturnal Erections Per Night - Min. Total",
        dash(
          format_decimal(safe_div(performance_data["duration_of_sleep_erections_in_seconds"], 60))
        )
      ],
      ["Sex & Solo Erections - Count", dash(format_decimal(performance_data["solo_sex_count"]))],
      [
        "Sex & Solo Erections - Min. Total",
        dash(
          format_decimal(
            safe_div(performance_data["duration_of_sex_solo_erections_in_seconds"], 60)
          )
        )
      ]
    ]

    profile_sheet =
      Worksheet.new("Patient Profile", ["", ""], patient_profile_rows,
        cols: [widths: %{1 => 44, 2 => 15}]
      )

    # Use records in the order given, incrementing suffix globally
    record_sheets =
      Enum.with_index(records, 1)
      |> Enum.map(fn {record, idx} ->
        date =
          case record.started_at do
            %NaiveDateTime{} = dt -> dt
            %DateTime{} = dt -> DateTime.to_naive(dt)
            _ -> nil
          end

        sheet_date =
          if date,
            do:
              String.pad_leading(Integer.to_string(date.day), 2, "0") <>
                "." <> String.pad_leading(Integer.to_string(date.month), 2, "0"),
            else: "Unknown"

        sheet_name =
          if idx == 1, do: "#{sheet_date} recording", else: "#{sheet_date} recording#{idx}"

        rs = record.recording_statistics || %{}

        # Separate record results by type
        nocturnal_results = Enum.filter(record.record_results || [], fn result ->
          result.erection_class in [:SLEEP, :MORNING]
        end)

        sex_solo_results = Enum.filter(record.record_results || [], fn result ->
          result.erection_class in [:SEX, :SOLO]
        end)

        base_rows = [
          ["Start Date and Time:", dash(record.started_at)],
          ["Total Duration", dash(format_decimal(safe_div(record.duration, 60)))],
          ["Alcohol Use", dash(format_decimal(record.consumed_alcohol_units))],
          ["Rec. Drugs", dash(record.recreational_drugs)],
          [
            "Medications:",
            dash(Enum.join(record.prescription_drugs_array || [], ", ") |> empty_to_dash())
          ],
          [],
          ["Recording breakdown", nil],
          ["Total Erections:", dash(format_decimal(length(record.record_results || [])))],
          [],
          ["Nocturnal & Morning Erections Count", dash(format_decimal(rs["nnm_erections"]))],
          [
            "Nocturnal & Morning Erections Average Duration",
            dash(format_decimal(rs["nnm_avg_duration"]))
          ],
          [
            "Nocturnal & Morning Erections Average Firmness Score",
            dash(format_decimal(rs["nnm_avg_firmness_score"]))
          ],
          [
            "Nocturnal & Morning Erections Max Firmness Score",
            dash(format_decimal(rs["nnm_max_firmness_score"]))
          ],
          [],
          ["Sex & Solo Erections Count", dash(format_decimal(rs["sns_erections"]))],
          ["Sex & Solo Erections Average Duration", dash(format_decimal(rs["sns_avg_duration"]))],
          [
            "Sex & Solo Erections Average Firmness Score",
            dash(format_decimal(rs["sns_avg_firmness_score"]))
          ],
          [
            "Sex & Solo Erections Max Firmness Score",
            dash(format_decimal(rs["sns_max_firmness_score"]))
          ],
          [],
          [],
          # Erection Break Down - Nocturnal section
          [nil, nil, "Erection Break Down", nil],
          [nil, nil, "Nocturnal", nil],
          [nil, nil, "Index", "Start time", "Max Firmness", "Total Duration", "Time 4-6", "Time 6-8", "Time 8-10"]
        ]

        nocturnal_rows = build_nocturnal_rows(nocturnal_results)

        sex_solo_header_rows = [
          [],
          [],
          # Sex & Solo section
          [nil, nil, "Sex & Solo", nil],
          [nil, nil, "Index", "Start time", "Max Firmness", "Total Duration", "Time 4-6", "Time 6-8", "Time 8-10"]
        ]

        sex_solo_rows = build_sex_solo_rows(sex_solo_results)

        rows = base_rows ++ nocturnal_rows ++ sex_solo_header_rows ++ sex_solo_rows

        worksheet = Worksheet.new(sheet_name, ["", ""], rows)

        {sheet_name, record.graph_img_url, worksheet}
      end)

    # Separate out the sheet/image mapping for Python
    sheet_img_map =
      record_sheets
      |> Enum.map(fn {sheet_name, img_url, _ws} -> {sheet_name, img_url} end)
      |> Enum.into(%{})

    # Only the worksheet structs for Elixir
    record_worksheets = Enum.map(record_sheets, fn {_, _, ws} -> ws end)

    workbook =
      Workbook.new("Firmtech Export")
      |> Workbook.add_worksheet(profile_sheet)
      |> add_recording_sheets(record_worksheets)

    stream = Exceed.stream!(workbook)
    # Compose the export file name
    first_name = user.first_name || "first"
    last_name = user.last_name || "last"
    file_name = "#{first_name}_#{last_name}___#{from_date}_to_#{to_date}.xlsx"
    file_path = "/tmp/#{file_name}"
    stream |> Stream.into(File.stream!(file_path)) |> Stream.run()

    # Write the sheet_img_map to a JSON file for the Python script
    json_uuid = Ecto.UUID.generate()
    img_map_path = "/tmp/firmtech_img_map_#{json_uuid}.json"
    File.write!(img_map_path, Jason.encode!(sheet_img_map))

    base_path = File.cwd!()
    IO.inspect(base_path, label: "base_path")
    # Call the Python script to embed images
    System.cmd(base_path <> "/venv/bin/python", [
      base_path <> "/python_scripts/embed_images.py",
      file_path,
      img_map_path
    ])

    # Call the Python script to format the Excel file
    System.cmd(base_path <> "/venv/bin/python", [
      base_path <> "/python_scripts/format.py",
      file_path
    ])

    {:ok, file_path}
  end

  defp add_recording_sheets(workbook, []), do: workbook

  defp add_recording_sheets(workbook, [sheet | rest]),
    do: add_recording_sheets(Workbook.add_worksheet(workbook, sheet), rest)

  defp calc_age(nil), do: nil
  defp calc_age(%Date{} = dob), do: Date.diff(Date.utc_today(), dob) |> div(365)

  defp format_decimal(nil), do: ""

  defp format_decimal(%Decimal{} = d),
    do: Decimal.round(d, 2) |> Decimal.to_float() |> :erlang.float_to_binary(decimals: 2)

  defp format_decimal(val) when is_float(val),
    do: :erlang.float_to_binary(Float.round(val, 2), decimals: 2)

  defp format_decimal(val) when is_integer(val),
    do: :erlang.float_to_binary(val * 1.0, decimals: 2)

  defp format_decimal(val) when is_binary(val), do: val

  defp safe_div(nil, _), do: nil
  defp safe_div(0, _), do: 0
  defp safe_div(val, divisor) when is_number(val), do: Float.round(val / divisor, 2)
  defp safe_div(val, divisor) when is_binary(val), do: safe_div(String.to_float(val), divisor)

  defp dash(nil), do: "-"
  defp dash(""), do: "-"
  defp dash(val) when is_number(val), do: format_decimal(val)
  defp dash(val), do: val

  defp empty_to_dash(""), do: "-"
  defp empty_to_dash(val), do: val

  defp build_nocturnal_rows([]), do: []

  defp build_nocturnal_rows(results) do
    data_rows = Enum.map(results, fn result ->
      duration_minutes = calculate_duration_minutes(result.start, result.end)
      [
        nil,
        nil,
        result.cluster,
        format_time(result.start),
        format_decimal(result.firmness),
        duration_minutes,
        safe_div(result.time_4_to_6 || 0, 60),
        safe_div(result.time_6_to_8 || 0, 60),
        safe_div(result.time_8_to_10 || 0, 60)
      ]
    end)

    # Add summary row
    avg_firmness = calculate_average_firmness(results)
    total_duration = calculate_total_duration_minutes(results)
    total_time_4_6 = safe_div(Enum.sum(Enum.map(results, &(&1.time_4_to_6 || 0))), 60)
    total_time_6_8 = safe_div(Enum.sum(Enum.map(results, &(&1.time_6_to_8 || 0))), 60)
    total_time_8_10 = safe_div(Enum.sum(Enum.map(results, &(&1.time_8_to_10 || 0))), 60)

    summary_row = [
      nil,
      nil,
      "",
      "Average / Sums",
      format_decimal(avg_firmness),
      total_duration,
      total_time_4_6,
      total_time_6_8,
      total_time_8_10
    ]

    # Return individual rows, not nested lists
    data_rows ++ [summary_row]
  end

  defp build_sex_solo_rows([]), do: []

  defp build_sex_solo_rows(results) do
    data_rows = Enum.map(results, fn result ->
      duration_minutes = calculate_duration_minutes(result.start, result.end)
      [
        nil,
        nil,
        result.cluster,
        format_time(result.start),
        format_decimal(result.firmness),
        duration_minutes,
        safe_div(result.time_4_to_6 || 0, 60),
        safe_div(result.time_6_to_8 || 0, 60),
        safe_div(result.time_8_to_10 || 0, 60)
      ]
    end)

    # Add summary row
    avg_firmness = calculate_average_firmness(results)
    total_duration = calculate_total_duration_minutes(results)
    total_time_4_6 = safe_div(Enum.sum(Enum.map(results, &(&1.time_4_to_6 || 0))), 60)
    total_time_6_8 = safe_div(Enum.sum(Enum.map(results, &(&1.time_6_to_8 || 0))), 60)
    total_time_8_10 = safe_div(Enum.sum(Enum.map(results, &(&1.time_8_to_10 || 0))), 60)

    summary_row = [
      nil,
      nil,
      "",
      "Average / Sums",
      format_decimal(avg_firmness),
      total_duration,
      total_time_4_6,
      total_time_6_8,
      total_time_8_10
    ]

    # Return individual rows, not nested lists
    data_rows ++ [summary_row]
  end

  defp calculate_duration_minutes(start_time, end_time) do
    case {start_time, end_time} do
      {%NaiveDateTime{} = start, %NaiveDateTime{} = end_time} ->
        NaiveDateTime.diff(end_time, start, :second) |> div(60)
      _ ->
        "{{duration in minutes}}"
    end
  end

  defp calculate_total_duration_minutes(results) do
    total_seconds = Enum.reduce(results, 0, fn result, acc ->
      case {result.start, result.end} do
        {%NaiveDateTime{} = start, %NaiveDateTime{} = end_time} ->
          acc + NaiveDateTime.diff(end_time, start, :second)
        _ ->
          acc
      end
    end)

    case total_seconds do
      0 -> "Sum of above"
      _ -> total_seconds |> div(60)
    end
  end


  defp calculate_average_firmness(results) do
    firmness_values = Enum.map(results, fn result ->
      case result.firmness do
        %Decimal{} = d -> Decimal.to_float(d)
        val when is_number(val) -> val
        _ -> 0
      end
    end)

    case firmness_values do
      [] -> 0
      values -> Enum.sum(values) / length(values)
    end
  end

  defp format_time(%NaiveDateTime{} = dt) do
    "#{String.pad_leading(Integer.to_string(dt.hour), 2, "0")}:#{String.pad_leading(Integer.to_string(dt.minute), 2, "0")}:#{String.pad_leading(Integer.to_string(dt.second), 2, "0")}"
  end

  defp format_time(_), do: ""
end
