defmodule UrlShortenerWeb.SlugController do
  use UrlShortenerWeb, :controller

  alias UrlShortener.Slugs
  alias UrlShortener.Slugs.Slug

  def index(conn, _params) do
    slugs = Slugs.list_slugs()
    render(conn, "index.html", slugs: slugs)
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
        |> redirect(to: Routes.slug_path(conn, :show, slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    slug = Slugs.get_slug!(id)
    render(conn, "show.html", slug: slug)
  end

  def edit(conn, %{"id" => id}) do
    slug = Slugs.get_slug!(id)
    changeset = Slugs.change_slug(slug)
    render(conn, "edit.html", slug: slug, changeset: changeset)
  end

  def update(conn, %{"id" => id, "slug" => slug_params}) do
    slug = Slugs.get_slug!(id)

    case Slugs.update_slug(slug, slug_params) do
      {:ok, slug} ->
        conn
        |> put_flash(:info, "Slug updated successfully.")
        |> redirect(to: Routes.slug_path(conn, :show, slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", slug: slug, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    slug = Slugs.get_slug!(id)
    {:ok, _slug} = Slugs.delete_slug(slug)

    conn
    |> put_flash(:info, "Slug deleted successfully.")
    |> redirect(to: Routes.slug_path(conn, :index))
  end
end
