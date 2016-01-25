use Mix.Config

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
#
# You should also configure the url host to something
# meaningful, we use this information when generating URLs.
#
# Finally, we also include the path to a manifest
# containing the digested version of static files. This
# manifest is generated by the mix phoenix.digest task
# which you typically run after static files are built.
config :vchat, Vchat.Endpoint,
  http: [port: 8080],
  url: [host: "vchat.domain4now.com", port: 8080],
  cache_static_manifest: "priv/static/manifest.json",
  server: true

# Do not print debug messages in production
config :logger, level: :info

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :vchat, Vchat.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :vchat, Vchat.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :vchat, Vchat.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
# import_config "prod.secret.exs"


config :vchat, 
  mailgun_domain: "https://api.mailgun.net/v3/sandbox2f6d41fc369d4382a65124a3febd6916.mailgun.org",
  mailgun_key: "key-f49093b5cddb89a71278f2c8cb0af144",
  from_email: "team@vchat.com"

# Configure your database
config :vchat, Vchat.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "vchat",
  password: "vchat",
  database: "vchat_prod",
  hostname: "localhost",
  pool_size: 10
