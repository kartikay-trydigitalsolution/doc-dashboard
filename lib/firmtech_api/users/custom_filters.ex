defmodule FirmtechApi.Users.CustomFilters do
  @moduledoc """
  Custom filter functions for Flop that handle computed fields.
  """
  import Ecto.Query

  @doc """
  Custom filter for age field, which is calculated from date_of_birth.
  """
  def age_filter(query, %Flop.Filter{value: value, op: op}, _opts) do
    today = Date.utc_today()
    days_per_year = 365
    
    # Calculate date_of_birth range based on age and operator
    # Use dynamic/1 (without bindings) and let Ecto figure out the bindings
    condition = case op do
      :== ->
        # For exact age, calculate date_of_birth range
        min_days = days_per_year * (value + 1)
        max_days = days_per_year * value
        min_date = Date.add(today, -min_days)
        max_date = Date.add(today, -max_days)
        dynamic([u], u.date_of_birth >= ^min_date and u.date_of_birth <= ^max_date)
      
      :>= ->
        # For age >= N, date_of_birth <= (today - N*365)
        max_days = days_per_year * value
        max_date = Date.add(today, -max_days)
        dynamic([u], u.date_of_birth <= ^max_date)
      
      :<= ->
        # For age <= N, date_of_birth >= (today - (N+1)*365)
        min_days = days_per_year * (value + 1)
        min_date = Date.add(today, -min_days)
        dynamic([u], u.date_of_birth >= ^min_date)
      
      :> ->
        # For age > N, date_of_birth < (today - N*365)
        max_days = days_per_year * value
        max_date = Date.add(today, -max_days)
        dynamic([u], u.date_of_birth < ^max_date)
      
      :< ->
        # For age < N, date_of_birth > (today - N*365)
        min_days = days_per_year * value
        min_date = Date.add(today, -min_days)
        dynamic([u], u.date_of_birth > ^min_date)
      
      :!= ->
        # For age != N, date_of_birth not in the range for age N
        min_days = days_per_year * (value + 1)
        max_days = days_per_year * value
        min_date = Date.add(today, -min_days)
        max_date = Date.add(today, -max_days)
        dynamic([u], u.date_of_birth < ^min_date or u.date_of_birth > ^max_date)
      
      _ ->
        nil
    end
    
    if condition do
      where(query, ^condition)
    else
      query
    end
  end
end
