defmodule UrlShortenerWeb.Router do
  use UrlShortenerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {UrlShortenerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", UrlShortenerWeb do
    pipe_through :browser

    get "/", SlugController, :new do
      # Only use this endpoint for creating new slugs
      post "/", SlugController, :create
    end

    # Use this endpoint to list all urls and slugs
    get "/stats", SlugController, :stats

    get "/*lookup_alias", SlugController, :redirect_to_url
  end
end
