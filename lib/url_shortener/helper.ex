defmodule UrlShortener.Helpers do
  @moduledoc """
  Helper functions for URL Shortener backend
  """
  @doc """
  Creates a random alphanumeric URL slug.
  Slugs can contain numerical digits and uppercase and lowercase letters.
  Default slug length is 5 characters.

  ## Examples

      iex> create_slug()
      "J6UIn"

      iex> create_slug(7)
      "SaYBTjH"

  """
  def create_random_slug(slug_length \\ 5) do
    # To create an N-length random string, randomly select N alphanumeric
    # characters into a list, then convert that charlist to a string.
    Enum.concat([?0..?9, ?a..?z, ?A..?Z])
    |> Enum.take_random(slug_length)
    |> to_string
  end
end
