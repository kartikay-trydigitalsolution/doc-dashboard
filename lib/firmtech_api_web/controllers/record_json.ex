defmodule FirmtechApiWeb.RecordJSON do
  alias FirmtechApi.Records.Record
  alias FirmtechApi.RecordResults.RecordResult

  @doc """
  Renders a list of records.
  """
  # def index(%{records: records}) do
  def index(%{meta: %Flop.Meta{} = meta, records: records}) do
    # %{data: for(record <- records, do: data(record))}
    %{data: for(record <- records, do: data(record)), meta: meta}
  end

  @doc """
  Renders a single record.
  """
  def show(%{record: record}) do
    %{data: data(record)}
  end

  defp data(%Record{} = record) do
    %{
      id: record.id,
      userId: record.userId,
      started_at: record.started_at,
      duration: record.duration,
      consumed_alcohol_units: record.consumed_alcohol_units,
      recreational_drugs: record.recreational_drugs,
      prescription_drugs_array: record.prescription_drugs_array,
      # record_results: record.record_results,
      graph_img_url: record.graph_img_url,
      record_results: record.record_results,
      recording_statistics: record.recording_statistics
    }
  end

  # defp data(%RecordResult{} = record_result) do
  #   %{
  #     cluster: record_result.cluster,
  #     start: record_result.start,
  #     end: record_result.end,
  #     global_best_score: record_result.global_best_score,
  #     firmness: record_result.firmness,
  #     erection_class: record_result.erection_class
  #   }
  # end
end
