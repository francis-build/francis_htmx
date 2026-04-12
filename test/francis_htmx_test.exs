defmodule FrancisHtmxTest do
  use ExUnit.Case
  alias FrancisHtmx

  describe "htmx/1" do
    test "renders html content with htmx inlined and renders assigns" do
      response =
        Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)

      assert response.status == 200
      assert response.headers["content-type"] == ["text/html; charset=utf-8"]
      assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]

      body = response.body
      html = Floki.parse_document!(body)

      # htmx.js is inlined, not loaded from CDN
      scripts = Floki.find(html, "script")
      assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)

      # Tailwind is still loaded from head option
      assert html
             |> Floki.find("script[src]")
             |> Floki.attribute("src") == ["https://cdn.tailwindcss.com"]

      assert html
             |> Floki.find("link")
             |> Floki.attribute("href") == ["/app.css"]

      assert html
             |> Floki.find("title")
             |> Floki.text() == "Testing HTMX"

      # Verify proper HTML5 structure
      assert body =~ ~s(<html lang="en">)
      assert body =~ ~s(<meta charset="utf-8">)
      assert body =~ ~s(<meta name="viewport")

      assert html
             |> Floki.find("body")
             |> Floki.find("div")
             |> Floki.text() == "test"
    end

    test "renders html content with htmx inlined and renders without assigns" do
      response =
        Req.get!("/", plug: FrancisHtmxTestHandlerWithoutAssigns)

      assert response.status == 200
      assert response.headers["content-type"] == ["text/html; charset=utf-8"]
      assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]

      body = response.body
      html = Floki.parse_document!(body)

      # htmx.js is inlined
      scripts = Floki.find(html, "script")
      assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)

      assert html
             |> Floki.find("script[src]")
             |> Floki.attribute("src") == ["https://cdn.tailwindcss.com"]

      assert html
             |> Floki.find("link")
             |> Floki.attribute("href") == ["/app.css"]

      assert html
             |> Floki.find("title")
             |> Floki.text() == "Testing HTMX"

      assert html
             |> Floki.find("body")
             |> Floki.find("div")
             |> Floki.text() == "test"
    end

    test "escapes title to prevent XSS" do
      response =
        Req.get!("/", plug: FrancisHtmxTestHandlerXSSTitle)

      assert response.status == 200

      body = response.body
      # The raw <script> tag in the title should be escaped
      refute body =~ "<title><script>alert('xss')</script></title>"
      assert body =~ "&lt;script&gt;"
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
