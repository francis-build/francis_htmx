defmodule FrancisHtmxTest do
  use ExUnit.Case

  describe "diag" do
    test "D1 Francis.HTML module is loaded" do
      assert Code.ensure_loaded?(Francis.HTML)
    end

    test "D2 Francis.ResponseHandlers module is loaded" do
      assert Code.ensure_loaded?(Francis.ResponseHandlers)
    end

    test "D3 handler module with assigns is loaded" do
      assert Code.ensure_loaded?(FrancisHtmxTestHandlerWithAssigns)
    end

    test "D4 handler module XSS is loaded" do
      assert Code.ensure_loaded?(FrancisHtmxTestHandlerXSSTitle)
    end

    test "D5 GET with assigns returns status 200" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      assert response.status == 200
    end

    test "D6 GET with assigns has content-type header" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      assert response.headers["content-type"] == ["text/html; charset=utf-8"]
    end

    test "D7 GET with assigns has cache-control header" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]
    end

    test "D8 GET with assigns body contains html lang" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      assert response.body =~ ~s(<html lang="en">)
    end

    test "D9 GET with assigns body contains htmx script inline" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      assert response.body =~ "htmx"
      refute response.body =~ "unpkg.com"
    end

    test "D10 GET XSS handler returns status 200" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerXSSTitle)
      assert response.status == 200
    end

    test "D11 Floki parses body from assigns handler" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      _html = Floki.parse_document!(response.body)
    end

    test "D12 Floki finds script elements" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      html = Floki.parse_document!(response.body)
      scripts = Floki.find(html, "script")
      assert length(scripts) > 0
    end

    test "D13 Floki finds script with src attribute" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      html = Floki.parse_document!(response.body)
      src_scripts = Floki.find(html, "script[src]")
      assert Floki.attribute(src_scripts, "src") == ["https://cdn.tailwindcss.com"]
    end

    test "D14 Floki finds link element" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      html = Floki.parse_document!(response.body)
      assert Floki.find(html, "link") |> Floki.attribute("href") == ["/app.css"]
    end

    test "D15 Floki finds title text" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      html = Floki.parse_document!(response.body)
      assert Floki.find(html, "title") |> Floki.text() == "Testing HTMX"
    end

    test "D16 Floki finds body div text" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      html = Floki.parse_document!(response.body)
      assert Floki.find(html, "body") |> Floki.find("div") |> Floki.text() == "test"
    end

    test "D17 inline htmx script contains htmx keyword" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)
      html = Floki.parse_document!(response.body)
      scripts = Floki.find(html, "script")
      assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)
    end
  end

  describe "htmx/1" do
    test "renders html content with htmx inlined and renders assigns" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)

      assert response.status == 200
      assert response.headers["content-type"] == ["text/html; charset=utf-8"]
      assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]

      body = response.body
      html = Floki.parse_document!(body)

      scripts = Floki.find(html, "script")
      assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)
      refute body =~ "unpkg.com"

      assert html
             |> Floki.find("script[src]")
             |> Floki.attribute("src") == ["https://cdn.tailwindcss.com"]

      assert html
             |> Floki.find("link")
             |> Floki.attribute("href") == ["/app.css"]

      assert html
             |> Floki.find("title")
             |> Floki.text() == "Testing HTMX"

      assert body =~ ~s(<html lang="en">)
      assert body =~ ~s(<meta charset="utf-8">)
      assert body =~ ~s(<meta name="viewport")

      assert html
             |> Floki.find("body")
             |> Floki.find("div")
             |> Floki.text() == "test"
    end

    test "renders html content with htmx inlined and renders without assigns" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithoutAssigns)

      assert response.status == 200
      assert response.headers["content-type"] == ["text/html; charset=utf-8"]
      assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]

      body = response.body
      html = Floki.parse_document!(body)

      scripts = Floki.find(html, "script")
      assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)
      refute body =~ "unpkg.com"

      assert html
             |> Floki.find("script[src]")
             |> Floki.attribute("src") == ["https://cdn.tailwindcss.com"]

      assert html
             |> Floki.find("link")
             |> Floki.attribute("href") == ["/app.css"]

      assert html
             |> Floki.find("title")
             |> Floki.text() == "Testing HTMX"

      assert body =~ ~s(<html lang="en">)
      assert body =~ ~s(<meta charset="utf-8">)
      assert body =~ ~s(<meta name="viewport")

      assert html
             |> Floki.find("body")
             |> Floki.find("div")
             |> Floki.text() == "test"
    end

    test "escapes title to prevent XSS" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerXSSTitle)

      assert response.status == 200

      body = response.body
      refute body =~ "<title><script>alert('xss')</script></title>"
      assert body =~ "&lt;script&gt;"
    end
  end

  describe "htmx/2" do
    test "allows overriding title and head via opts" do
      response = Req.get!("/", plug: FrancisHtmxTestHandlerWithOpts)

      assert response.status == 200
      assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]

      body = response.body
      html = Floki.parse_document!(body)

      assert html
             |> Floki.find("title")
             |> Floki.text() == "Overridden Title"

      assert html
             |> Floki.find("link")
             |> Floki.attribute("href") == ["/custom.css"]

      scripts = Floki.find(html, "script")
      assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)
      refute body =~ "unpkg.com"

      assert body =~ ~s(<html lang="en">)
      assert body =~ ~s(<meta charset="utf-8">)

      assert html
             |> Floki.find("body")
             |> Floki.find("div")
             |> Floki.text() == "override test"
    end
  end
end

defmodule FrancisHtmxTestHandlerWithAssigns do
  use Francis

  use FrancisHtmx,
    title: "Testing HTMX",
    head: ~E"""
      <script src="https://cdn.tailwindcss.com"></script>
      <link href="/app.css" rel="stylesheet">
    """

  htmx(fn _ ->
    assigns = %{content: "test"}

    ~E"""
    <div><%= @content %></div>
    """
  end)
end

defmodule FrancisHtmxTestHandlerWithoutAssigns do
  use Francis

  use FrancisHtmx,
    title: "Testing HTMX",
    head: ~E"""
      <script src="https://cdn.tailwindcss.com"></script>
      <link href="/app.css" rel="stylesheet">
    """

  htmx(fn _ ->
    ~E"""
    <div>test</div>
    """
  end)
end

defmodule FrancisHtmxTestHandlerXSSTitle do
  use Francis

  use FrancisHtmx,
    title: "<script>alert('xss')</script>"

  htmx(fn _ ->
    ~E"""
    <div>safe</div>
    """
  end)
end

defmodule FrancisHtmxTestHandlerWithOpts do
  use Francis
  use FrancisHtmx, title: "Default Title"

  htmx(
    fn _ ->
      ~E"""
      <div>override test</div>
      """
    end,
    title: "Overridden Title",
    head: ~E"""
      <link href="/custom.css" rel="stylesheet">
    """
  )
end
