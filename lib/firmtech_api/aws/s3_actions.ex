defmodule FirmtechApi.Aws.S3Actions do
  @moduledoc """
  Module for interacting with AWS S3.
  """

  @default_bucket "amplify-firmtechbackendge-readingsstoragebucketbd5-nlt2picud0lk"

  def get_presigned_url(bucket, key) do
    target_bucket =
      case bucket do
        b when is_binary(b) and b != "" -> b
        _ ->
          System.get_env("AWS_IMAGES_BUCKET") ||
            System.get_env("READINGS_BUCKET_NAME") ||
            @default_bucket
      end

    case ExAws.Config.new(:s3)
         |> ExAws.S3.presigned_url(
           :get,
           target_bucket,
           key,
           expires_in: 3600
         ) do
      {:ok, presigned_url} ->
        presigned_url
      _ ->
        nil
    end
  end
end
