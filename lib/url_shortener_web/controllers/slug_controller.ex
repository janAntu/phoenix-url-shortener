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
end
