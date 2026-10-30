config = Application.fetch_env!(:firmtech_api, FirmtechApi.Mailer)
IO.puts("adapter:    " <> inspect(config[:adapter]))
IO.puts("region:     " <> (config[:region] || "nil"))
IO.puts("access_key: " <> (if config[:access_key], do: "***SET***", else: "nil"))
IO.puts("secret:     " <> (if config[:secret], do: "***SET***", else: "nil"))

email =
  Swoosh.Email.new()
  |> Swoosh.Email.to({"firmtech dev", "developer.tdsl3@gmail.com"})
  |> Swoosh.Email.from({"firmtechring", "no-reply@sandbox.firmtechring.com"})
  |> Swoosh.Email.subject("SES LIVE TEST " <> NaiveDateTime.to_string(NaiveDateTime.utc_now()))
  |> Swoosh.Email.text_body("Ye Amazon SES se real email hai.")

case FirmtechApi.Mailer.deliver(email) do
  {:ok, result} ->
    IO.puts("RESULT=DELIVERED")
    IO.puts(inspect(result, limit: :infinity))

  {:error, reason} ->
    IO.puts("RESULT=FAILED")
    IO.puts(inspect(reason, limit: :infinity))
end
