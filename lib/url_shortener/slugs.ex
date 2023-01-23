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
  def create_slug(attrs \\ %{}) do
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
end
