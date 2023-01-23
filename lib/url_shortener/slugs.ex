defmodule UrlShortener.Slugs do
  @moduledoc """
  The Slugs context.
  """

  import Ecto.Query, warn: false
  alias UrlShortener.Repo

  alias UrlShortener.Helpers
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
  Returns an `%Ecto.Changeset{}` for tracking slug changes.

  ## Examples

      iex> change_slug(slug)
      %Ecto.Changeset{data: %Slug{}}

  """
  def change_slug(%Slug{} = slug, attrs \\ %{}) do
    Slug.changeset(slug, attrs)
  end

  @doc """
  Creates a slug. If the provided alias is blank, a random alias will be created.

  ## Examples

      iex> create_slug(%{"original_url" => "https://www.google.com", "alias" => "google"})
      {:ok, %Slug{"original_url" => "https://www.google.com", "alias" => "google"}}

      iex> create_slug(%{"original_url" => "https://www.google.com", "alias" => ""})
      {:ok, %Slug{"original_url" => "https://www.google.com", "alias" => "d8S9w"}}

      iex> create_slug(%{"original_url" => nil, "alias" => nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_slug(attrs) do
    # If user does not provide an alias, then generate a random slug
    if attrs["alias"] == "" do
      generate_and_insert_slug(attrs)
    # If user provides an alias, do a simple insert and return the changeset
    else
      insert_slug(attrs)
    end
  end

  defp insert_slug(attrs) do
    %Slug{}
    |> Slug.changeset(attrs)
    |> Repo.insert()
  end

  defp generate_and_insert_slug(attrs, alias_length \\ 5) do
    random_slug = Helpers.create_random_slug(alias_length)
    case insert_slug(Map.put(attrs, "alias", random_slug)) do
      {:ok, insert_result} -> {:ok, insert_result}
      {:error, changeset} ->
        # If the randomly generated slug was already taken,
        # try again with a different random slug.
        if slug_taken?(changeset) do
          generate_and_insert_slug(attrs, alias_length + 1)
        # If any other error occurs, send the error back to the user
        # but don't send back the slug (leave the slug blank).
        else
          {:error, %{changeset | data: %{changeset.data | alias: ""}}}
        end
    end
  end

  def slug_taken?(%Ecto.Changeset{} = changeset) do
    case changeset.errors[:alias] do
      {_, [constraint: :unique, constraint_name: _]} -> true
      _ -> false
    end
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
