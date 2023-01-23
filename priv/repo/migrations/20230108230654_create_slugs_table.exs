defmodule UrlShortener.Repo.Migrations.CreateSlugsTable do
  use Ecto.Migration

  def change do
    create table(:slugs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :original_url, :string
      add :alias, :string
      add :count_visits, :integer, default: 0

      timestamps()
    end

    create unique_index(:slugs, [:alias])
  end
end
