defmodule Vchat.UserMailer do
  use Mailgun.Client, domain: Application.get_env(:vchat, :mailgun_domain),
                      key: Application.get_env(:vchat, :mailgun_key)

  @from Application.get_env(:vchat, :from_email)


def send_account_verification_email(conn, user) do
  send_email to: user.email,
             from: @from,
             subject: "Welcome to Vchat, kindly verify your email address",
             html: Phoenix.View.render_to_string(Vchat.UserMailerView, "verification.html", conn: conn, user: user)
end

end