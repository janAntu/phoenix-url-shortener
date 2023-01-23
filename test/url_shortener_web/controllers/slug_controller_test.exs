defmodule UrlShortenerWeb.SlugControllerTest do
  use UrlShortenerWeb.ConnCase

  import UrlShortener.SlugsFixtures

  @create_attrs %{alias: "some alias", count_visits: 42, original_url: "some original_url"}
  @update_attrs %{alias: "some updated alias", count_visits: 43, original_url: "some updated original_url"}
  @invalid_attrs %{alias: nil, count_visits: nil, original_url: nil}

  describe "index" do
    test "lists all slugs", %{conn: conn} do
      conn = get(conn, Routes.slug_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Slugs"
    end
  end

  describe "new slug" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.slug_path(conn, :new))
      assert html_response(conn, 200) =~ "New Slug"
    end
  end

  describe "create slug" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.slug_path(conn, :create), slug: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.slug_path(conn, :show, id)

      conn = get(conn, Routes.slug_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Slug"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.slug_path(conn, :create), slug: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Slug"
    end
  end

  describe "edit slug" do
    setup [:create_slug]

    test "renders form for editing chosen slug", %{conn: conn, slug: slug} do
      conn = get(conn, Routes.slug_path(conn, :edit, slug))
      assert html_response(conn, 200) =~ "Edit Slug"
    end
  end

  describe "update slug" do
    setup [:create_slug]

    test "redirects when data is valid", %{conn: conn, slug: slug} do
      conn = put(conn, Routes.slug_path(conn, :update, slug), slug: @update_attrs)
      assert redirected_to(conn) == Routes.slug_path(conn, :show, slug)

      conn = get(conn, Routes.slug_path(conn, :show, slug))
      assert html_response(conn, 200) =~ "some updated alias"
    end

    test "renders errors when data is invalid", %{conn: conn, slug: slug} do
      conn = put(conn, Routes.slug_path(conn, :update, slug), slug: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Slug"
    end
  end

  describe "delete slug" do
    setup [:create_slug]

    test "deletes chosen slug", %{conn: conn, slug: slug} do
      conn = delete(conn, Routes.slug_path(conn, :delete, slug))
      assert redirected_to(conn) == Routes.slug_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.slug_path(conn, :show, slug))
      end
    end
  end

  defp create_slug(_) do
    slug = slug_fixture()
    %{slug: slug}
  end
end
