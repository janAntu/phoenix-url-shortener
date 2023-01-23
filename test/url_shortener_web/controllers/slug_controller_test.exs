defmodule UrlShortenerWeb.SlugControllerTest do
  use UrlShortenerWeb.ConnCase

  import UrlShortener.SlugsFixtures

  @create_attrs %{original_url: "https://en.wikipedia.org/", alias: "wiki"}
  @invalid_attrs %{original_url: nil, alias: nil}

  describe "new slug" do
    test "renders form", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Create a short URL"
      assert html_response(conn, 200) =~ "Create URL"
    end
  end

  describe "create slug" do
    test "displays new slug when slug is valid", %{conn: conn} do
      conn = post(conn, "/", slug: @create_attrs)

      assert html_response(conn, 200) =~ "Created new short URL!"
      assert html_response(conn, 200) =~ @create_attrs.original_url
      assert html_response(conn, 200) =~ @create_attrs.alias

      conn = get(conn, "/stats")
      assert html_response(conn, 200) =~ @create_attrs.original_url
      @create_attrs.alias

    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.slug_path(conn, :create), slug: @invalid_attrs)
      assert html_response(conn, 200) =~ "Create a short URL"
      assert html_response(conn, 200) =~ "Oops, something went wrong!"
    end
  end

  describe "redirection" do
    setup [:create_slug]

    test "redirects to external url", %{conn: conn} do
      conn = get(conn, "/#{@create_attrs.alias}")
      assert redirected_to(conn) == @create_attrs.original_url
    end

    test "redirects to 404 for nonexistant slug", %{conn: conn} do
      conn = get(conn, "/nonexistant")
      assert html_response(conn, 404) =~
        "Error 404: URL shortcut \"nonexistant\" not found"
    end

    test "stats page updated after visiting external url", %{conn: conn} do
      for _ <- 1..7 do
        _conn = get(conn, "/#{@create_attrs.alias}")
      end

      conn = get(conn, "/stats")
      assert html_response(conn, 200) =~
        Regex.compile!("#{@create_attrs.alias}[\<\\/td\\>\\s]*7")
    end
  end

  defp create_slug(_) do
    slug = slug_fixture()
    %{slug: slug}
  end
end
