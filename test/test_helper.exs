# Mock create_random_slug for unit tests (unless overridden)
Mimic.copy(UrlShortener.Helpers)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(UrlShortener.Repo, :manual)
