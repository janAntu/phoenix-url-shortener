defmodule UrlShortener.SlugsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `UrlShortener.Slugs` context.
  """

  @doc """
  Generate a slug.
  """
  def slug_fixture(attrs \\ %{}) do
    {:ok, slug} =
      attrs
      |> Enum.into(%{
        alias: "some alias",
        count_visits: 42,
        original_url: "some original_url"
      })
      |> UrlShortener.Slugs.create_slug()

    slug
  end
end
