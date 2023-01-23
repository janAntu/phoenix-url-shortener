defmodule UrlShortener.SlugsTest do
  use UrlShortener.DataCase, async: true

  alias UrlShortener.Slugs
  alias UrlShortener.Slugs.Slug

  # Use Mimic to mock the create_random_slug helper method
  use Mimic.DSL

  describe "slugs" do
    import UrlShortener.SlugsFixtures

    test "list_slugs/0 returns all slugs" do
      slug = slug_fixture()
      assert Slugs.list_slugs() == [slug]
    end

    test "change_slug/1 returns a slug changeset" do
      slug = slug_fixture()
      assert %Ecto.Changeset{} = Slugs.change_slug(slug)
    end
  end

  describe "create_slug" do
    @valid_attrs %{"original_url" => "https://en.wikipedia.org/", "alias" =>  "wiki"}
    @invalid_attrs %{"original_url" => nil, "alias" =>  nil}

    test "create_slug/1 with valid data creates a slug" do
      assert {:ok, %Slug{} = slug} = Slugs.create_slug(@valid_attrs)
      assert slug.count_visits == 0
      assert slug.original_url == "https://en.wikipedia.org/"
      assert slug.alias == "wiki"
    end

    test "create_slug/1 with invalid data doesn't insert new record" do
      assert {:error, %Ecto.Changeset{}} = Slugs.create_slug(@invalid_attrs)
      assert Slugs.list_slugs() == []
    end

    test "create_slug/1 enforces unique slug names" do
      assert {:ok, first_slug} = Slugs.create_slug(@valid_attrs)
      assert {:error, changeset} = Slugs.create_slug(@valid_attrs)
      assert %{alias: ["has already been taken"]} = errors_on(changeset)
      assert Slugs.list_slugs() == [first_slug]
    end

    test "does not accept invalid urls" do
      for invalid_url <- [
        "wikipedia",
        "en.wikipedia.org",
        "https://en.wikipedia.org",
        "https://en.wikipedia.org/   "
      ] do
        attrs = Map.put(@valid_attrs, "original_url", invalid_url)
        assert {:error, changeset} = Slugs.create_slug(attrs)
        assert %{original_url: ["has invalid format"]} = errors_on(changeset)
      end
      assert Slugs.list_slugs() == []
    end

    test "does not accept slugs over 72 characters long" do
      attrs = Map.put(@valid_attrs, "alias", String.duplicate("w", 73))
      {:error, changeset} = Slugs.create_slug(attrs)
      assert %{alias: ["should be at most 72 character(s)"]} = errors_on(changeset)

      attrs = Map.put(@valid_attrs, "alias", ",&$ ")
      {:error, changeset} = Slugs.create_slug(attrs)
      assert %{alias: ["has invalid format"]} = errors_on(changeset)

      assert Slugs.list_slugs() == []
    end
  end
end
