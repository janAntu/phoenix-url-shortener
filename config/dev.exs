import Config

# Configure your database
config :url_shortener, UrlShortener.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "url_shortener_dev",
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
  http: [ip: {127, 0, 0, 1}, port: 8080],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "Sp9byBnc0g90bQLhQ7sHKbTZLz13G7pQyJjFeKkrvA6tVg9C5vo9l1ZlX5svO6uv",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :url_shortener, UrlShortenerWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/url_shortener_web/(live|views)/.*(ex)$",
      ~r"lib/url_shortener_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
