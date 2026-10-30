defmodule FirmtechApi.Repo do
  use Ecto.Repo,
    otp_app: :firmtech_api,
    adapter: Ecto.Adapters.Postgres

  # @doc """
  # Helper function to execute raw SQL queries.
  # """
  # def execute_raw(sql, params \\ []) do
  #   {:ok, result} = Ecto.Adapters.SQL.query(__MODULE__, sql, params)
  #   result
  # end

  # @doc """
  # Helper function to begin a transaction.
  # """
  # def transaction_with_retry(fun, attempts \\ 3) do
  #   case transaction(fun) do
  #     {:ok, result} ->
  #       {:ok, result}
  #     {:error, error} when attempts > 1 ->
  #       Process.sleep(100) # Brief delay before retry
  #       transaction_with_retry(fun, attempts - 1)
  #     error ->
  #       error
  #   end
  # end
end
