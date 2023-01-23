defmodule UrlShortener.Slugs.Slug do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "slugs" do
    field :count_visits, :integer, default: 0
    field :original_url, :string
    field :alias, :string

    timestamps()
  end

  @doc false
  def changeset(slug, attrs) do
    slug
    |> cast(attrs, [:original_url, :alias])
    |> validate_required([:original_url, :alias])
    # Only allow valid URL that start with http(s)://{domain}/
    # Use \S to avoid whitespace in or after URL
    |> validate_format(:original_url, ~r/^https?:\/\/\S*\/\S*$/)
    # Slugs must be valid URL suffixes and shouldn't be excessively long.
    # The `stats` route can't be reserved since it's already used.
    |> validate_exclusion(:alias, ["stats"])
    |> validate_length(:alias, min: 1, max: 72)
    |> validate_format(:alias, ~r/[A-Za-z0-9_-]+/)
    # Don't allow multiple slugs with different emails
    |> unique_constraint(:alias)
  end
end
