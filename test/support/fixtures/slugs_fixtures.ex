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
        original_url: "https://en.wikipedia.org/",
        alias: "wiki"
      })
      |> UrlShortener.Slugs.create_slug()

    slug
  end
end
