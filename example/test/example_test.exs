defmodule ExampleTest do
  use ExUnit.Case

  test "renders html content with htmx inlined and initial color demo" do
    response = Req.get!("/", plug: Example)

    assert response.status == 200
    assert response.headers["content-type"] == ["text/html; charset=utf-8"]
    assert response.headers["cache-control"] == ["no-cache, no-store, must-revalidate"]

    body = response.body
    html = Floki.parse_document!(body)

    # Check that htmx is inlined (no CDN script src)
    scripts = Floki.find(html, "script")
    assert Enum.any?(scripts, fn script -> Floki.text(script) =~ "htmx" end)
    assert Floki.find(html, "script[src]") == []

    # Check proper HTML5 structure
    assert body =~ ~s(<html lang="en">)
    assert body =~ ~s(<meta charset="utf-8">)
    assert body =~ ~s(<meta name="viewport")

    # Check title is set correctly
    assert html
           |> Floki.find("title")
           |> Floki.text() == "HTMX Example"

    # Check that the color demo div is present with correct attributes
    color_demo_div = Floki.find(html, "div[hx-get='/colors']")

    assert length(color_demo_div) == 1

    assert Floki.attribute(color_demo_div, "hx-trigger") == ["every 1s"]

    # Check that the initial color demo paragraph is present
    assert html
           |> Floki.find("p#color-demo")
           |> Floki.text() == "Color Swap Demo"

    # Check that the smooth CSS class is applied
    assert html
           |> Floki.find("p#color-demo")
           |> Floki.attribute("class") == ["smooth"]

    # Check that the CSS styles are included
    assert html
           |> Floki.find("style")
           |> Floki.text() =~ ".smooth"
  end

  test "renders color endpoint with dynamic color" do
    response = Req.get!("/colors", plug: Example)

    assert response.status == 200

    body = response.body
    html = Floki.parse_document!(body)

    # Check that the color demo paragraph is present
    color_param = Floki.find(html, "p#color-demo")

    assert length(color_param) == 1
    assert Floki.text(color_param) =~ "Color Swap Demo"

    # Check that the smooth CSS class is applied
    assert Floki.attribute(color_param, "class") == ["smooth"]

    # Check that a style attribute with color is present
    style_attr = Floki.attribute(color_param, "style")

    assert length(style_attr) == 1
    assert hd(style_attr) =~ "color:#"
  end
end
