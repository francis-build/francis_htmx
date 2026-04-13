defmodule FrancisHtmxTest do
  use ExUnit.Case

  describe "htmx/1" do
    test "DIAGNOSTIC: check handler module and francis version" do
      # Check that handler module is available
      assert Code.ensure_loaded?(FrancisHtmxTestHandlerWithAssigns),
        "Handler module not loaded"

      # Check Francis.HTML availability
      assert Code.ensure_loaded?(Francis.HTML),
        "Francis.HTML module not available - wrong Francis version?"

      # Check Francis version
      francis_vsn =
        Application.spec(:francis, :vsn) |> to_string()

      assert francis_vsn =~ "0.3",
        "Expected Francis ~> 0.3.x, got: #{francis_vsn}"

      # Try the actual request and capture any error
      try do
        response = Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)

        flunk(
          "DIAG: status=#{response.status} " <>
            "content-type=#{inspect(response.headers["content-type"])} " <>
            "cache-control=#{inspect(response.headers["cache-control"])} " <>
            "body_size=#{byte_size(to_string(response.body))} " <>
            "body_start=#{String.slice(to_string(response.body), 0, 300)}"
        )
      rescue
        e ->
          flunk("DIAG ERROR: #{Exception.format(:error, e, __STACKTRACE__)}")
      end
    end

    test "renders html content with htmx inlined and renders assigns" do
      response =
        Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)

      assert response.status == 200,
        "Expected 200, got #{response.status}. Body: #{String.slice(to_string(response.body), 0, 500)}"

      assert response.headers["content-type"] == ["text/html; charset=utf-8"],
        "content-type: #{inspect(response.headers["content-type"])}"

      assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"],
        "cache-control: #{inspect(response.headers["cache-control"])}, all headers: #{inspect(Map.keys(response.headers))}"

      body = response.body
      html = Floki.parse_document!(body)

      # htmx.js is inlined, not loaded from CDN
      scripts = Floki.find(html, "script")
      assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)
      refute body =~ "unpkg.com"

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

      # htmx.js is inlined, not loaded from CDN
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

      # Verify proper HTML5 structure
      assert body =~ ~s(<html lang="en">)
      assert body =~ ~s(<meta charset="utf-8">)
      assert body =~ ~s(<meta name="viewport")

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

  describe "htmx/2" do
    test "allows overriding title and head via opts" do
      response =
        Req.get!("/", plug: FrancisHtmxTestHandlerWithOpts)

      assert response.status == 200
      assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]

      body = response.body
      html = Floki.parse_document!(body)

      # Title is overridden via htmx/2 opts
      assert html
             |> Floki.find("title")
             |> Floki.text() == "Overridden Title"

      # Head content from opts is present
      assert html
             |> Floki.find("link")
             |> Floki.attribute("href") == ["/custom.css"]

      # htmx.js is still inlined
      scripts = Floki.find(html, "script")
      assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)
      refute body =~ "unpkg.com"

      # Verify proper HTML5 structure
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
