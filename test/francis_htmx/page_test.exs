defmodule FrancisHtmx.PageTest do
  use ExUnit.Case
  alias FrancisHtmx.Page

  setup do
    {:ok, conn: Plug.Test.conn(:get, "/")}
  end

  describe "render_page/3 content preservation" do
    test "direct request includes content inline in full page", %{conn: conn} do
      result = Page.render_page(conn, fn -> "<h1>About</h1>" end)

      assert result.status == 200
      assert result.resp_body =~ "<!DOCTYPE html>"
      assert result.resp_body =~ "<h1>About</h1>"
      refute result.resp_body =~ "Loading..."
      refute result.resp_body =~ ~s(hx-trigger="load")
    end

    test "HTMX request returns content only", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "hx-request", "true")
      result = Page.render_page(conn, fn -> "<h1>About</h1>" end)

      assert result.status == 200
      assert result.resp_body == "<h1>About</h1>"
      refute result.resp_body =~ "<!DOCTYPE html>"
    end

    test "history restore request returns full page with content", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("hx-request", "true")
        |> Plug.Conn.put_req_header("hx-history-restore-request", "true")

      result = Page.render_page(conn, fn -> "<h1>About</h1>" end)

      assert result.status == 200
      assert result.resp_body =~ "<!DOCTYPE html>"
      assert result.resp_body =~ "<h1>About</h1>"
    end

    test "content_fn is always called regardless of request type", %{conn: conn} do
      call_count = :counters.new(1, [:atomics])

      content_fn = fn ->
        :counters.add(call_count, 1, 1)
        "<p>rendered</p>"
      end

      Page.render_page(conn, content_fn)
      assert :counters.get(call_count, 1) == 1

      htmx_conn = Plug.Conn.put_req_header(conn, "hx-request", "true")
      Page.render_page(htmx_conn, content_fn)
      assert :counters.get(call_count, 1) == 2

      restore_conn =
        conn
        |> Plug.Conn.put_req_header("hx-request", "true")
        |> Plug.Conn.put_req_header("hx-history-restore-request", "true")

      Page.render_page(restore_conn, content_fn)
      assert :counters.get(call_count, 1) == 3
    end
  end

  describe "render_page/3 default layout" do
    test "uses hx-boost on body", %{conn: conn} do
      result = Page.render_page(conn, fn -> "content" end)

      assert result.resp_body =~ ~s(hx-boost="true")
    end

    test "does not include hardcoded CSS", %{conn: conn} do
      result = Page.render_page(conn, fn -> "content" end)

      refute result.resp_body =~ "box-sizing: border-box"
      refute result.resp_body =~ ".btn"
      refute result.resp_body =~ ".card"
    end

    test "uses custom title", %{conn: conn} do
      result = Page.render_page(conn, fn -> "content" end, title: "My App")

      assert result.resp_body =~ "<title>My App</title>"
    end

    test "uses default title when none provided", %{conn: conn} do
      result = Page.render_page(conn, fn -> "content" end)

      assert result.resp_body =~ "<title>FrancisHTMX App</title>"
    end

    test "does not generate navigation HTML", %{conn: conn} do
      result = Page.render_page(conn, fn -> "content" end)

      refute result.resp_body =~ "<nav"
    end

    test "uses custom target id", %{conn: conn} do
      result = Page.render_page(conn, fn -> "content" end, target: "app-root")

      assert result.resp_body =~ ~s(id="app-root")
    end

    test "sets content-type to text/html", %{conn: conn} do
      result = Page.render_page(conn, fn -> "content" end)

      assert Plug.Conn.get_resp_header(result, "content-type") == ["text/html; charset=utf-8"]
    end

    test "includes meta charset and viewport", %{conn: conn} do
      result = Page.render_page(conn, fn -> "content" end)

      assert result.resp_body =~ ~s(<meta charset="utf-8">)
      assert result.resp_body =~ ~s(<meta name="viewport")
    end
  end

  describe "render_page/3 with custom layout" do
    defp custom_layout(assigns) do
      """
      <!DOCTYPE html>
      <html>
        <head><title>#{assigns.title}</title></head>
        <body>
          <nav><a href="/">Home</a></nav>
          <main>#{assigns.content}</main>
        </body>
      </html>
      """
    end

    test "uses layout function for direct requests", %{conn: conn} do
      result = Page.render_page(conn, fn -> "<h1>Hello</h1>" end, layout: &custom_layout/1)

      assert result.resp_body =~ "<nav><a href=\"/\">Home</a></nav>"
      assert result.resp_body =~ "<main><h1>Hello</h1></main>"
    end

    test "passes title to layout", %{conn: conn} do
      result = Page.render_page(conn, fn -> "c" end, layout: &custom_layout/1, title: "Custom")

      assert result.resp_body =~ "<title>Custom</title>"
    end

    test "HTMX request bypasses layout entirely", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "hx-request", "true")
      result = Page.render_page(conn, fn -> "<h1>Partial</h1>" end, layout: &custom_layout/1)

      assert result.resp_body == "<h1>Partial</h1>"
      refute result.resp_body =~ "<nav>"
    end

    test "history restore uses layout with content", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("hx-request", "true")
        |> Plug.Conn.put_req_header("hx-history-restore-request", "true")

      result = Page.render_page(conn, fn -> "<h1>Restored</h1>" end, layout: &custom_layout/1)

      assert result.resp_body =~ "<nav>"
      assert result.resp_body =~ "<h1>Restored</h1>"
    end
  end
end
