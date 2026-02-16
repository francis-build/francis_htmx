defmodule FrancisHtmx.HeadersTest do
  use ExUnit.Case
  alias FrancisHtmx.Headers

  setup do
    conn = %Plug.Conn{
      req_headers: [],
      resp_headers: []
    }

    {:ok, conn: conn}
  end

  describe "htmx_request?/1" do
    test "returns true when HX-Request header is present", %{conn: conn} do
      conn = %{conn | req_headers: [{"hx-request", "true"}]}
      assert Headers.htmx_request?(conn)
    end

    test "returns false when HX-Request header is missing", %{conn: conn} do
      refute Headers.htmx_request?(conn)
    end
  end

  describe "get_trigger/1" do
    test "returns trigger ID when present", %{conn: conn} do
      conn = %{conn | req_headers: [{"hx-trigger", "submit-btn"}]}
      assert Headers.get_trigger(conn) == "submit-btn"
    end

    test "returns nil when trigger header is missing", %{conn: conn} do
      assert Headers.get_trigger(conn) == nil
    end
  end

  describe "get_target/1" do
    test "returns target ID when present", %{conn: conn} do
      conn = %{conn | req_headers: [{"hx-target", "results"}]}
      assert Headers.get_target(conn) == "results"
    end

    test "returns nil when target header is missing", %{conn: conn} do
      assert Headers.get_target(conn) == nil
    end
  end

  describe "get_current_url/1" do
    test "returns current URL when present", %{conn: conn} do
      conn = %{conn | req_headers: [{"hx-current-url", "https://example.com/page"}]}
      assert Headers.get_current_url(conn) == "https://example.com/page"
    end

    test "returns nil when current URL header is missing", %{conn: conn} do
      assert Headers.get_current_url(conn) == nil
    end
  end

  describe "boosted?/1" do
    test "returns true when request is boosted", %{conn: conn} do
      conn = %{conn | req_headers: [{"hx-boosted", "true"}]}
      assert Headers.boosted?(conn)
    end

    test "returns false when request is not boosted", %{conn: conn} do
      refute Headers.boosted?(conn)
    end
  end

  describe "location/1" do
    test "sets HX-Location header", %{conn: conn} do
      conn = Headers.location(conn, "/new-page")
      assert Plug.Conn.get_resp_header(conn, "hx-location") == ["/new-page"]
    end
  end

  describe "location/2 with options" do
    test "sets HX-Location header with JSON options", %{conn: conn} do
      conn = Headers.location(conn, "/new-page", target: "#main", swap: "outerHTML")
      [location_header] = Plug.Conn.get_resp_header(conn, "hx-location")
      decoded = Jason.decode!(location_header)

      assert decoded["path"] == "/new-page"
      assert decoded["target"] == "#main"
      assert decoded["swap"] == "outerHTML"
    end
  end

  describe "push_url/1" do
    test "sets HX-Push-Url header with URL", %{conn: conn} do
      conn = Headers.push_url(conn, "/new-url")
      assert Plug.Conn.get_resp_header(conn, "hx-push-url") == ["/new-url"]
    end

    test "sets HX-Push-Url header with boolean", %{conn: conn} do
      conn = Headers.push_url(conn, true)
      assert Plug.Conn.get_resp_header(conn, "hx-push-url") == ["true"]
    end
  end

  describe "replace_url/1" do
    test "sets HX-Replace-Url header", %{conn: conn} do
      conn = Headers.replace_url(conn, "/updated-url")
      assert Plug.Conn.get_resp_header(conn, "hx-replace-url") == ["/updated-url"]
    end
  end

  describe "hx_redirect/2" do
    test "sets HX-Redirect header", %{conn: conn} do
      conn = Headers.hx_redirect(conn, "/login")
      assert Plug.Conn.get_resp_header(conn, "hx-redirect") == ["/login"]
    end
  end

  describe "refresh/1" do
    test "sets HX-Refresh header", %{conn: conn} do
      conn = Headers.refresh(conn)
      assert Plug.Conn.get_resp_header(conn, "hx-refresh") == ["true"]
    end
  end

  describe "retarget/1" do
    test "sets HX-Retarget header", %{conn: conn} do
      conn = Headers.retarget(conn, "#different-div")
      assert Plug.Conn.get_resp_header(conn, "hx-retarget") == ["#different-div"]
    end
  end

  describe "reswap/1" do
    test "sets HX-Reswap header", %{conn: conn} do
      conn = Headers.reswap(conn, "outerHTML")
      assert Plug.Conn.get_resp_header(conn, "hx-reswap") == ["outerHTML"]
    end
  end

  describe "trigger/1" do
    test "sets HX-Trigger header with single event", %{conn: conn} do
      conn = Headers.trigger(conn, "itemAdded")
      assert Plug.Conn.get_resp_header(conn, "hx-trigger") == ["itemAdded"]
    end

    test "sets HX-Trigger header with multiple events", %{conn: conn} do
      conn = Headers.trigger(conn, ["event1", "event2"])
      assert Plug.Conn.get_resp_header(conn, "hx-trigger") == ["event1, event2"]
    end
  end

  describe "trigger/2 with detail" do
    test "sets HX-Trigger header with event detail", %{conn: conn} do
      conn = Headers.trigger(conn, "itemAdded", %{id: 123})
      [trigger_header] = Plug.Conn.get_resp_header(conn, "hx-trigger")
      decoded = Jason.decode!(trigger_header)

      assert decoded["itemAdded"]["id"] == 123
    end
  end

  describe "trigger_after_swap/1" do
    test "sets HX-Trigger-After-Swap header", %{conn: conn} do
      conn = Headers.trigger_after_swap(conn, "swapped")
      assert Plug.Conn.get_resp_header(conn, "hx-trigger-after-swap") == ["swapped"]
    end
  end

  describe "trigger_after_settle/1" do
    test "sets HX-Trigger-After-Settle header", %{conn: conn} do
      conn = Headers.trigger_after_settle(conn, "settled")
      assert Plug.Conn.get_resp_header(conn, "hx-trigger-after-settle") == ["settled"]
    end
  end

  describe "get_trigger_name/1" do
    test "returns trigger name when present", %{conn: conn} do
      conn = %{conn | req_headers: [{"hx-trigger-name", "my-button"}]}
      assert Headers.get_trigger_name(conn) == "my-button"
    end

    test "returns nil when trigger name header is missing", %{conn: conn} do
      assert Headers.get_trigger_name(conn) == nil
    end
  end

  describe "get_prompt/1" do
    test "returns prompt value when present", %{conn: conn} do
      conn = %{conn | req_headers: [{"hx-prompt", "Enter name"}]}
      assert Headers.get_prompt(conn) == "Enter name"
    end

    test "returns nil when prompt header is missing", %{conn: conn} do
      assert Headers.get_prompt(conn) == nil
    end
  end

  describe "history_restore_request?/1" do
    test "returns true when history restore header is present", %{conn: conn} do
      conn = %{conn | req_headers: [{"hx-history-restore-request", "true"}]}
      assert Headers.history_restore_request?(conn)
    end

    test "returns false when history restore header is missing", %{conn: conn} do
      refute Headers.history_restore_request?(conn)
    end
  end

  describe "reselect/2" do
    test "sets HX-Reselect header", %{conn: conn} do
      conn = Headers.reselect(conn, "#content")
      assert Plug.Conn.get_resp_header(conn, "hx-reselect") == ["#content"]
    end
  end

  describe "trigger_after_swap/2 variants" do
    test "sets header with list of events", %{conn: conn} do
      conn = Headers.trigger_after_swap(conn, ["event1", "event2"])
      assert Plug.Conn.get_resp_header(conn, "hx-trigger-after-swap") == ["event1, event2"]
    end

    test "sets header with event detail", %{conn: conn} do
      conn = Headers.trigger_after_swap(conn, "myEvent", %{key: "value"})
      [header] = Plug.Conn.get_resp_header(conn, "hx-trigger-after-swap")
      decoded = Jason.decode!(header)
      assert decoded["myEvent"]["key"] == "value"
    end
  end

  describe "trigger_after_settle/2 variants" do
    test "sets header with list of events", %{conn: conn} do
      conn = Headers.trigger_after_settle(conn, ["event1", "event2"])
      assert Plug.Conn.get_resp_header(conn, "hx-trigger-after-settle") == ["event1, event2"]
    end

    test "sets header with event detail", %{conn: conn} do
      conn = Headers.trigger_after_settle(conn, "myEvent", %{key: "value"})
      [header] = Plug.Conn.get_resp_header(conn, "hx-trigger-after-settle")
      decoded = Jason.decode!(header)
      assert decoded["myEvent"]["key"] == "value"
    end
  end
end
