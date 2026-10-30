defmodule FirmtechApi.Emails do
  import Swoosh.Email

  @from_address {"Firmtech", "noreply@myfirmtech.com"}
  @cc_address "waseem@moblers.com"

  @doc """
  Sends a verification code to a user's email.
  """
  def send_verification_code(to_email, code) do
    %Swoosh.Email{}
    |> to(to_email)
    |> from(@from_address)
    |> subject("Your Verification Code")
    |> html_body("""
    <h1>Verification Code</h1>
    <p>Your verification code is: <strong>#{code}</strong></p>
    <p>This code will expire in 15 minutes.</p>
    """)
    |> text_body("""
    Verification Code

    Your verification code is: #{code}

    This code will expire in 15 minutes.
    """)
    |> FirmtechApi.Mailer.deliver()
  end

  @doc """
  Sends an Excel export as an email attachment.
  """
  def send_excel_export(to_email, file_path, full_name, from_date, to_date) do
    %Swoosh.Email{}
    |> to(to_email)
    |> cc(@cc_address)
    |> from(@from_address)
    |> subject("Data Export for #{full_name} from #{from_date} to #{to_date}")
    |> html_body("")
    |> text_body("")
    |> attachment(file_path)
    |> FirmtechApi.Mailer.deliver()
  end
end
