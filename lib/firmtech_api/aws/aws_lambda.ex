defmodule AwsLambda do
  @moduledoc """
  Module for invoking AWS Lambda functions synchronously with parameters.
  """

  @doc """
  Executes an AWS Lambda function synchronously with the given parameters.

  ## Parameters
    - function_name: Name or ARN of the Lambda function
    - payload: Map containing the parameters to pass to the Lambda function
    - region: AWS region (optional, defaults to configured region)

  ## Returns
    - {:ok, response} on success
    - {:error, reason} on failure
  """
  def invoke_sync(function_name, payload, region \\ nil) do
    # Convert the payload to JSON
    payload_json = Jason.encode!(payload)

    # Create the request
    request =
      ExAws.Lambda.invoke(function_name, payload_json, %{"InvocationType" => "RequestResponse"})

    # Apply region if specified
    opts = if region, do: [region: region], else: []

    # Execute the Lambda function
    case ExAws.request(request, opts) do
      {:ok, %{"statusCode" => 200} = resp} ->
        case resp["body"] do
          body when is_binary(body) ->
            case Jason.decode(body) do
              {:ok, %{"errorMessage" => msg}} -> {:error, {:lambda_error, msg}}
              {:ok, decoded} -> {:ok, decoded}
              {:error, _} -> {:ok, body}
            end

          %{"errorMessage" => msg} ->
            {:error, {:lambda_error, msg}}

          other when is_map(other) ->
            {:ok, other}

          nil ->
            {:ok, resp}
        end

      {:ok, %{"errorMessage" => msg}} ->
        {:error, {:lambda_error, msg}}

      {:ok, other} ->
        {:error, {:unexpected_response, other}}

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end
end

# Example matching your error message
defmodule ExampleProcessRScore do
  def run do
    # Define the parameters as in your error message
    params = %{
      "context" => %{
        "user_id" => "41dc1d63-ee55-4f68-a4dd-b0919eaa4bbd"
      },
      "params" => %{
        "querystring" => %{
          "dashboard" => true,
          "from" => "2024-08-01",
          "to" => "2025-08-01",
          "utc_offset" => "180"
        }
      }
    }

    # Invoke the Lambda function using exact function name from your error
    case ProcessRScore.invoke_sync("processRScore-staging", params, "us-east-1") do
      {:ok, response} ->
        IO.puts("Lambda executed successfully!")
        IO.inspect(response, label: "Response")

      {:error, reason} ->
        IO.puts("Error executing Lambda function:")
        IO.inspect(reason)
    end
  end
end
