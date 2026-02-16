defmodule FrancisHtmx.ComponentsTest do
  use ExUnit.Case
  alias FrancisHtmx.Components

  describe "wrapper/3" do
    test "creates a div wrapper with id and content" do
      result = Components.wrapper("main-content", "", fn -> "Inner content" end)
      assert result =~ ~s(<div id="main-content")
      assert result =~ "Inner content"
      assert result =~ "</div>"
    end

    test "creates a div wrapper with attributes" do
      result = Components.wrapper("main", ~s(class="container"), fn -> "Content" end)
      assert result =~ ~s(id="main")
      assert result =~ ~s(class="container")
    end

    test "creates a div wrapper with default empty attrs" do
      result = Components.wrapper("section", fn -> "Default" end)
      assert result =~ ~s(<div id="section")
      assert result =~ "Default"
    end
  end

  describe "fragment/2" do
    test "creates a fragment with id and content" do
      result = Components.fragment("user-list", fn -> "<ul><li>User 1</li></ul>" end)
      assert result =~ ~s(<div id="user-list">)
      assert result =~ "<ul><li>User 1</li></ul>"
      assert result =~ "</div>"
    end
  end

  describe "htmx_or_full/2" do
    test "returns htmx content when HX-Request header is present" do
      conn = %Plug.Conn{req_headers: [{"hx-request", "true"}]}

      result =
        Components.htmx_or_full(conn,
          htmx: fn -> "<div>Partial</div>" end,
          full: fn -> "<html>Full</html>" end
        )

      assert result == "<div>Partial</div>"
    end

    test "returns full content when HX-Request header is missing" do
      conn = %Plug.Conn{req_headers: []}

      result =
        Components.htmx_or_full(conn,
          htmx: fn -> "<div>Partial</div>" end,
          full: fn -> "<html>Full</html>" end
        )

      assert result == "<html>Full</html>"
    end
  end

end
