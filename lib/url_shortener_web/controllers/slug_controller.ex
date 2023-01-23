defmodule UrlShortenerWeb.SlugController do
  use UrlShortenerWeb, :controller

  alias UrlShortener.Slugs
  alias UrlShortener.Slugs.Slug

  def stats(conn, _params) do
    slugs = Slugs.list_slugs()
    render(conn, "stats.html", slugs: slugs)
  end

  def new(conn, _params) do
    changeset = Slugs.change_slug(%Slug{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"slug" => slug_params}) do
    case Slugs.create_slug(slug_params) do
      {:ok, slug} ->
        conn
        |> put_flash(:info, "Slug created successfully.")
        |> render("show.html", slug: slug)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def redirect_to_url(conn, %{"lookup_alias" => [lookup_alias]}) do
    case Slugs.get_url_from_slug(lookup_alias) do
      {:ok, original_url} ->
        conn
        |> put_flash(:info, "Redirecting to original URL")
        |> redirect(external: original_url)
      # If user enters a slug that isn't in the database,
      # redirect to a custom 404 error page.
      {:error, _reason} ->
        conn
        |> put_status(404)
        |> render("error.html", lookup_alias: lookup_alias)
    end
  end
end
