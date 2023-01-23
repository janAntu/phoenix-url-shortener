defmodule UrlShortener.SlugsTest do
  use UrlShortener.DataCase

  alias UrlShortener.Slugs

  describe "slugs" do
    alias UrlShortener.Slugs.Slug

    import UrlShortener.SlugsFixtures

    @invalid_attrs %{alias: nil, count_visits: nil, original_url: nil}

    test "list_slugs/0 returns all slugs" do
      slug = slug_fixture()
      assert Slugs.list_slugs() == [slug]
    end

    test "get_slug!/1 returns the slug with given id" do
      slug = slug_fixture()
      assert Slugs.get_slug!(slug.id) == slug
    end

    test "create_slug/1 with valid data creates a slug" do
      valid_attrs = %{alias: "some alias", count_visits: 42, original_url: "some original_url"}

      assert {:ok, %Slug{} = slug} = Slugs.create_slug(valid_attrs)
      assert slug.alias == "some alias"
      assert slug.count_visits == 42
      assert slug.original_url == "some original_url"
    end

    test "create_slug/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Slugs.create_slug(@invalid_attrs)
    end

    test "update_slug/2 with valid data updates the slug" do
      slug = slug_fixture()
      update_attrs = %{alias: "some updated alias", count_visits: 43, original_url: "some updated original_url"}

      assert {:ok, %Slug{} = slug} = Slugs.update_slug(slug, update_attrs)
      assert slug.alias == "some updated alias"
      assert slug.count_visits == 43
      assert slug.original_url == "some updated original_url"
    end

    test "update_slug/2 with invalid data returns error changeset" do
      slug = slug_fixture()
      assert {:error, %Ecto.Changeset{}} = Slugs.update_slug(slug, @invalid_attrs)
      assert slug == Slugs.get_slug!(slug.id)
    end

    test "delete_slug/1 deletes the slug" do
      slug = slug_fixture()
      assert {:ok, %Slug{}} = Slugs.delete_slug(slug)
      assert_raise Ecto.NoResultsError, fn -> Slugs.get_slug!(slug.id) end
    end

    test "change_slug/1 returns a slug changeset" do
      slug = slug_fixture()
      assert %Ecto.Changeset{} = Slugs.change_slug(slug)
    end
  end
end
