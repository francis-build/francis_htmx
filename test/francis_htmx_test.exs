defmodule FrancisHtmxTest do
  use ExUnit.Case
  alias FrancisHtmx

  describe "htmx/1" do
    test "renders html content with htmx loaded and renders assigns" do
      response =
        Req.get!("/", plug: FrancisHtmxTestHandlerWithAssigns)

      assert response.status == 200
      assert response.headers["content-type"] == ["text/html; charset=utf-8"]

      body = response.body
      html = Floki.parse_document!(body)

      assert html
             |> Floki.find("script")
             |> Floki.attribute("src") == [
               "https://cdn.tailwindcss.com",
               "https://unpkg.com/htmx.org@2"
             ]

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

    test "renders html content with htmx loaded and renders without assigns" do
      response =
        Req.get!("/", plug: FrancisHtmxTestHandlerWithoutAssigns)

      assert response.status == 200
      assert response.headers["content-type"] == ["text/html; charset=utf-8"]

      body = response.body
      html = Floki.parse_document!(body)

      assert html
             |> Floki.find("script")
             |> Floki.attribute("src") == [
               "https://cdn.tailwindcss.com",
               "https://unpkg.com/htmx.org@2"
             ]

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

    test "raises error if version format is invalid" do
      assert_raise RuntimeError,
                   "Invalid version format. Expected format is 'x.y.z' or 'x.y.*'. Got: 'invalid'",
                   fn ->
                     defmodule FrancisHtmxFailedVersionTest do
                       use Francis

                       use FrancisHtmx, version: "invalid"

                       htmx(fn _ ->
                         assigns = %{title: "test"}
                         ~E"<div>Test</div>"
                       end)
                     end
                   end
    end
  end
end

defmodule FrancisHtmxTestHandlerWithAssigns do
  use Francis

  use FrancisHtmx,
    version: "2",
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
    version: "2",
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
