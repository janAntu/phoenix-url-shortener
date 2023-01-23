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

  describe "routing_multiple_urls" do
    @url1 "https://en.wikipedia.org/"
    @url2 "https://xkcd.com/1700"
    @valid_attrs1 %{"original_url" => @url1, "alias" =>  "wiki"}
    @valid_attrs2 %{"original_url" => @url2, "alias" =>  "xkcd"}

    setup do
      Slugs.create_slug(@valid_attrs1)
      Slugs.create_slug(@valid_attrs2)
      :ok
    end

    test "get_url_from_slug/1 fetches correct urls" do
      assert {:ok, @url1} == Slugs.get_url_from_slug("wiki")
      assert {:ok, @url2} == Slugs.get_url_from_slug("xkcd")
    end

    test "get_url_from_slug/1 error handling" do
      assert {:error,  "Alias not found in database"} == Slugs.get_url_from_slug("fake")
    end

    test "increment_visit_count/1 increments counts correctly" do
      assert {:ok, @url1} == Slugs.get_url_from_slug("wiki")
      assert {:ok, @url1} == Slugs.get_url_from_slug("wiki")
      assert {:ok, @url2} == Slugs.get_url_from_slug("xkcd")
      assert {:ok, @url2} == Slugs.get_url_from_slug("xkcd")
      assert {:ok, @url2} == Slugs.get_url_from_slug("xkcd")

      assert [first_slug, second_slug] = Slugs.list_slugs()
      assert first_slug.count_visits == 2
      assert second_slug.count_visits == 3
    end

    test "get_csv_data/0" do
      for _ <- 1..5 do Slugs.get_url_from_slug("wiki") end
      for _ <- 1..7 do Slugs.get_url_from_slug("xkcd") end

      assert Slugs.get_csv_data() == Enum.join([
        Enum.join(["Original URL", "Alias", "Number of Visits"], ","),
        Enum.join([@url1, "wiki", "5"], ","),
        Enum.join([@url2, "xkcd", "7"], ","),
        ""
      ], "\r\n")
    end
  end

  describe "random_slug_generation" do
    @valid_attrs %{"original_url" => "https://en.wikipedia.org/", "alias" =>  ""}

    setup do
      stub UrlShortener.Helpers.create_random_slug(l), do: String.duplicate("x", l)
      :ok
    end

    test "create_slug/1 creates random slug if none provided" do
      assert {:ok, %Slug{} = slug} = Slugs.create_slug(@valid_attrs)
      assert slug.original_url == "https://en.wikipedia.org/"
      assert slug.alias == "xxxxx"
    end

    test "create_slug/1 avoid random slug collisions" do
      assert {:ok, %Slug{} = slug1} = Slugs.create_slug(@valid_attrs)
      assert {:ok, %Slug{} = slug2} = Slugs.create_slug(@valid_attrs)
      assert slug1.alias == "xxxxx"
      assert slug2.alias == "xxxxxx"
    end

    test "create_slug/1 invalid URL and empty slug" do
      attrs = %{"original_url" => "en.wikipedia.org", "alias" =>  ""}
      assert {:error, changeset} = Slugs.create_slug(attrs)
      assert %{original_url: ["has invalid format"]} = errors_on(changeset)
      assert changeset.data.alias == ""
      assert changeset.changes.alias == ""
    end
  end
end
