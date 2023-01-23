defmodule UrlShortener.Slugs.Slug do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "slugs" do
    field :alias, :string
    field :count_visits, :integer
    field :original_url, :string

    timestamps()
  end

  @doc false
  def changeset(slug, attrs) do
    slug
    |> cast(attrs, [:original_url, :alias, :count_visits])
    |> validate_required([:original_url, :alias, :count_visits])
  end
end
