import Config

config :url_shortener, UrlShortener.Repo,
  username: System.get_env("PGUSER"),
  password: System.get_env("PGPASSWORD"),
  hostname: System.get_env("PGHOST"),
  database: System.get_env("PGDATABASE"),
  port: System.get_env("PGPORT"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :url_shortener, UrlShortenerWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 8080],
  check_origin: false,
  debug_errors: true,
  secret_key_base: "/O8BaKWbQbXMFSOkORyBvRlfeC69XvU0Zu3wecQmu+uBfF+7xzvM+f7EoGyQOtMA"

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
