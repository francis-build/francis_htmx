defmodule ExampleTest do
  use ExUnit.Case

  test "renders root page with htmx inlined and all demo sections" do
    response = Req.get!("/", plug: Example)

    assert response.status == 200
    assert response.headers["content-type"] == ["text/html; charset=utf-8"]
    assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]

    body = response.body
    html = Floki.parse_document!(body)

    # htmx.js is inlined (no CDN script src)
    scripts = Floki.find(html, "script")
    assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)
    assert Floki.find(html, "script[src]") == []
    refute body =~ "unpkg.com"

    # Proper HTML5 structure
    assert body =~ ~s(<html lang="en">)
    assert body =~ ~s(<meta charset="utf-8">)
    assert body =~ ~s(<meta name="viewport")

    # Title
    assert html |> Floki.find("title") |> Floki.text() == "HTMX Example"

    # Custom styles from :head option are present
    assert html |> Floki.find("style") |> Floki.text() =~ ".smooth"
    assert html |> Floki.find("style") |> Floki.text() =~ ".card"

    # Color swap section
    color_demo_div = Floki.find(html, "div[hx-get='/colors']")
    assert length(color_demo_div) == 1
    assert Floki.attribute(color_demo_div, "hx-trigger") == ["every 1s"]
    assert html |> Floki.find("p#color-demo") |> Floki.text() == "Color Swap Demo"
    assert html |> Floki.find("p#color-demo") |> Floki.attribute("class") == ["smooth"]

    # Greeting form section
    form = Floki.find(html, "form[hx-post='/greet']")
    assert length(form) == 1
    assert Floki.attribute(form, "hx-target") == ["#greeting"]
    assert Floki.attribute(form, "hx-swap") == ["innerHTML"]
    assert html |> Floki.find("input[name='name']") |> length() == 1

    # Server time section
    time_div = Floki.find(html, "div[hx-get='/time']")
    assert length(time_div) == 1
    assert Floki.attribute(time_div, "hx-trigger") == ["load, every 5s"]
  end

  test "renders color endpoint with dynamic color" do
    response = Req.get!("/colors", plug: Example)

    assert response.status == 200

    body = response.body
    html = Floki.parse_document!(body)

    color_param = Floki.find(html, "p#color-demo")
    assert length(color_param) == 1
    assert Floki.text(color_param) =~ "Color Swap Demo"
    assert Floki.attribute(color_param, "class") == ["smooth"]

    style_attr = Floki.attribute(color_param, "style")
    assert length(style_attr) == 1
    assert hd(style_attr) =~ "color:#"
  end

  test "renders greeting with provided name" do
    response = Req.post!("/greet", plug: Example, form: [name: "Francis"])

    assert response.status == 200

    body = response.body
    html = Floki.parse_document!(body)

    assert html |> Floki.find("strong") |> Floki.text() == "Francis"
  end

  test "renders greeting with default name when empty" do
    response = Req.post!("/greet", plug: Example, form: [])

    assert response.status == 200

    body = response.body
    html = Floki.parse_document!(body)

    assert html |> Floki.find("strong") |> Floki.text() == "World"
  end

  test "renders server time" do
    response = Req.get!("/time", plug: Example)

    assert response.status == 200

    body = response.body
    assert body =~ "UTC"
  end
end
