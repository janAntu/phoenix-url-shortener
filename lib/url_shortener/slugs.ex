defmodule UrlShortener.Slugs do
  @moduledoc """
  The Slugs context.
  """

  import Ecto.Query, warn: false
  alias UrlShortener.Repo

  alias UrlShortener.Slugs.Slug

  @doc """
  Returns the list of slugs.

  ## Examples

      iex> list_slugs()
      [%Slug{}, ...]

  """
  def list_slugs do
    Repo.all(Slug)
  end

  @doc """
  Creates a slug.

  ## Examples

      iex> create_slug(%{field: value})
      {:ok, %Slug{}}

      iex> create_slug(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_slug(attrs) do
    %Slug{}
    |> Slug.changeset(attrs)
    |> Repo.insert()
  end


  @doc """
  Returns an `%Ecto.Changeset{}` for tracking slug changes.

  ## Examples

      iex> change_slug(slug)
      %Ecto.Changeset{data: %Slug{}}

  """
  def change_slug(%Slug{} = slug, attrs \\ %{}) do
    Slug.changeset(slug, attrs)
  end

  @doc """
  Look up original url matching slug and increments count_visits by one

  ## Examples

      iex> get_url_from_slug!("wiki")
      {:ok, "https://en.wikipedia.org/"}

      iex> get_slug!("nonexistent")
      {:error,  "Slug not found in database"}

  """
  def get_url_from_slug(lookup_alias) do
    query = from slug in "slugs",
            where: slug.alias == type(^lookup_alias, :string),
            select: slug.original_url
    # Since update_all returns the number of updated rows and the selected
    # results, use the return to determine whether the URL was found.
    case Repo.update_all(query, [inc: [count_visits: 1]]) do
      {0, _} -> {:error,  "Alias not found in database"}
      {1, [original_url]} -> {:ok,  original_url}
    end
  end
end
