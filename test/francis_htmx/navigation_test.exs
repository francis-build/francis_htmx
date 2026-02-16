defmodule FrancisHtmx.NavigationTest do
  use ExUnit.Case
  alias FrancisHtmx.Navigation

  setup do
    {:ok, conn: Plug.Test.conn(:get, "/")}
  end

  describe "nav_link/3" do
    test "generates boosted link by default" do
      result = Navigation.nav_link("/home", "Home")
      assert result =~ "href=\"/home\""
      assert result =~ "hx-boost=\"true\""
      assert result =~ "hx-push-url=\"true\""
      assert result =~ ">Home</a>"
    end

    test "generates link with custom class" do
      result = Navigation.nav_link("/profile", "Profile", class: "nav-item")
      assert result =~ "class=\"nav-item\""
    end

    test "generates link without boost when disabled" do
      result = Navigation.nav_link("/delete", "Delete", boost: false)
      refute result =~ "hx-boost"
      assert result =~ "href=\"/delete\""
    end

    test "generates link with confirmation" do
      result = Navigation.nav_link("/delete", "Delete", confirm: "Are you sure?")
      assert result =~ "hx-confirm=\"Are you sure?\""
    end
  end

  describe "nav_menu/2" do
    test "generates navigation menu with links" do
      items = [
        {"/", "Home"},
        {"/about", "About"}
      ]

      result = Navigation.nav_menu(items)
      assert result =~ "<nav class=\"nav\">"
      assert result =~ "href=\"/\""
      assert result =~ "href=\"/about\""
      assert result =~ ">Home</a>"
      assert result =~ ">About</a>"
    end

    test "applies active class to active items" do
      items = [
        {"/", "Home", active: true},
        {"/about", "About"}
      ]

      result = Navigation.nav_menu(items, active_class: "current")
      assert result =~ "current"
    end
  end

  describe "breadcrumbs/2" do
    test "generates breadcrumb navigation" do
      items = [
        {"/", "Home"},
        {"/products", "Products"},
        {nil, "Details"}
      ]

      result = Navigation.breadcrumbs(items)
      assert result =~ "<div class=\"breadcrumbs\">"
      assert result =~ "href=\"/\""
      assert result =~ "href=\"/products\""
      assert result =~ ">Details</span>"
    end

    test "uses custom separator" do
      items = [{"/", "Home"}, {nil, "About"}]
      result = Navigation.breadcrumbs(items, separator: ">")
      assert result =~ ">"
    end
  end

  describe "back_button/2" do
    test "generates back button with default text" do
      result = Navigation.back_button()
      assert result =~ "<button"
      assert result =~ "onclick=\"history.back()\""
      assert result =~ ">Back</button>"
    end

    test "generates back button with custom text and class" do
      result = Navigation.back_button("Go Back", class: "btn")
      assert result =~ "class=\"btn\""
      assert result =~ ">Go Back</button>"
    end
  end

  describe "redirect_to/3" do
    test "redirects HTMX requests using HX-Location header", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "hx-request", "true")
      result = Navigation.redirect_to(conn, "/login")

      assert Plug.Conn.get_resp_header(result, "hx-location") == ["/login"]
    end

    test "redirects regular requests using HTTP redirect", %{conn: conn} do
      result = Navigation.redirect_to(conn, "/login")

      assert Plug.Conn.get_resp_header(result, "location") == ["/login"]
      assert result.status == 302
    end
  end

  describe "pagination/2" do
    test "generates pagination with prev and next links" do
      conn = %Plug.Conn{}

      result = Navigation.pagination(conn, page: 2, total_pages: 5, path: "/items")

      assert result =~ "<ul class=\"pagination\">"
      assert result =~ "Previous"
      assert result =~ "Next"
      assert result =~ "href=\"/items?page=1\""
      assert result =~ "href=\"/items?page=3\""
    end

    test "disables previous link on first page" do
      conn = %Plug.Conn{}

      result = Navigation.pagination(conn, page: 1, total_pages: 5, path: "/items")

      assert result =~ "class=\"disabled\""
      refute result =~ "href=\"/items?page=0\""
    end

    test "disables next link on last page" do
      conn = %Plug.Conn{}

      result = Navigation.pagination(conn, page: 5, total_pages: 5, path: "/items")

      assert result =~ "class=\"disabled\""
      refute result =~ "href=\"/items?page=6\""
    end
  end

  describe "page/4" do
    test "renders content for HTMX requests", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "hx-request", "true")
      result = Navigation.page(conn, "Test", fn -> "<div>Content</div>" end)

      assert result.status == 200
      assert result.resp_body =~ "<div>Content</div>"
    end

    test "renders full layout for regular requests", %{conn: conn} do
      result = Navigation.page(conn, "TestPage", fn -> "<div>Content</div>" end)

      assert result.status == 200
      assert result.resp_body =~ "<!DOCTYPE html>"
      assert result.resp_body =~ "<title>TestPage</title>"
    end

    test "uses custom layout function when provided", %{conn: conn} do
      layout_fn = fn title, content ->
        "<custom>#{title}: #{content}</custom>"
      end

      result = Navigation.page(conn, "Custom", fn -> "body" end, layout: layout_fn)

      assert result.status == 200
      assert result.resp_body == "<custom>Custom: body</custom>"
    end

    test "skips push_url header when push_url: false", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "hx-request", "true")
      result = Navigation.page(conn, "Test", fn -> "content" end, push_url: false)

      assert result.status == 200
      assert Plug.Conn.get_resp_header(result, "hx-push-url") == []
    end
  end
end
