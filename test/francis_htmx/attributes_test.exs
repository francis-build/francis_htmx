defmodule FrancisHtmx.AttributesTest do
  use ExUnit.Case
  alias FrancisHtmx.Attributes

  describe "HTTP method attributes" do
    test "hx_get/1 generates correct attribute" do
      assert Attributes.hx_get("/api/data") == ~s(hx-get="/api/data")
    end

    test "hx_post/1 generates correct attribute" do
      assert Attributes.hx_post("/api/submit") == ~s(hx-post="/api/submit")
    end

    test "hx_put/1 generates correct attribute" do
      assert Attributes.hx_put("/api/update/1") == ~s(hx-put="/api/update/1")
    end

    test "hx_patch/1 generates correct attribute" do
      assert Attributes.hx_patch("/api/update/1") == ~s(hx-patch="/api/update/1")
    end

    test "hx_delete/1 generates correct attribute" do
      assert Attributes.hx_delete("/api/delete/1") == ~s(hx-delete="/api/delete/1")
    end
  end

  describe "targeting and swapping" do
    test "hx_target/1 generates correct attribute" do
      assert Attributes.hx_target("#results") == ~s(hx-target="#results")
    end

    test "hx_swap/1 generates correct attribute" do
      assert Attributes.hx_swap("outerHTML") == ~s(hx-swap="outerHTML")
    end

    test "hx_select/1 generates correct attribute" do
      assert Attributes.hx_select("#content") == ~s(hx-select="#content")
    end
  end

  describe "triggering" do
    test "hx_trigger/1 generates correct attribute" do
      assert Attributes.hx_trigger("click") == ~s(hx-trigger="click")
    end

    test "hx_trigger/1 supports complex triggers" do
      assert Attributes.hx_trigger("every 2s") == ~s(hx-trigger="every 2s")
    end
  end

  describe "data handling" do
    test "hx_vals/1 generates correct attribute" do
      result = Attributes.hx_vals(~s({"key": "value"}))
      assert result == ~s(hx-vals="{\\"key\\": \\"value\\"}")
    end

    test "hx_include/1 generates correct attribute" do
      assert Attributes.hx_include("#form-1") == ~s(hx-include="#form-1")
    end

    test "hx_headers/1 generates correct attribute" do
      result = Attributes.hx_headers(~s({"X-Custom": "value"}))
      assert result =~ ~s(hx-headers=)
    end
  end

  describe "user interaction" do
    test "hx_confirm/1 generates correct attribute" do
      assert Attributes.hx_confirm("Are you sure?") == ~s(hx-confirm="Are you sure?")
    end

    test "hx_prompt/1 generates correct attribute" do
      assert Attributes.hx_prompt("Enter name") == ~s(hx-prompt="Enter name")
    end
  end

  describe "URL handling" do
    test "hx_push_url/1 with string generates correct attribute" do
      assert Attributes.hx_push_url("/new-url") == ~s(hx-push-url="/new-url")
    end

    test "hx_push_url/1 with boolean generates correct attribute" do
      assert Attributes.hx_push_url(true) == ~s(hx-push-url="true")
    end

    test "hx_replace_url/1 generates correct attribute" do
      assert Attributes.hx_replace_url("/updated-url") == ~s(hx-replace-url="/updated-url")
    end
  end

  describe "advanced features" do
    test "hx_swap_oob/1 generates correct attribute" do
      assert Attributes.hx_swap_oob(true) == ~s(hx-swap-oob="true")
    end

    test "hx_indicator/1 generates correct attribute" do
      assert Attributes.hx_indicator("#spinner") == ~s(hx-indicator="#spinner")
    end

    test "hx_disabled_elt/1 generates correct attribute" do
      assert Attributes.hx_disabled_elt("this") == ~s(hx-disabled-elt="this")
    end

    test "hx_sync/1 generates correct attribute" do
      assert Attributes.hx_sync("this:drop") == ~s(hx-sync="this:drop")
    end

    test "hx_boost/1 generates correct attribute" do
      assert Attributes.hx_boost(true) == ~s(hx-boost="true")
    end

    test "hx_validate/1 generates correct attribute" do
      assert Attributes.hx_validate(true) == ~s(hx-validate="true")
    end

    test "hx_disable/1 generates correct attribute" do
      assert Attributes.hx_disable(true) == ~s(hx-disable="true")
    end
  end

  describe "combine/1" do
    test "combines multiple attributes with spaces" do
      result =
        Attributes.combine([
          Attributes.hx_get("/data"),
          Attributes.hx_trigger("click"),
          Attributes.hx_target("#results")
        ])

      assert result == ~s(hx-get="/data" hx-trigger="click" hx-target="#results")
    end

    test "handles empty list" do
      assert Attributes.combine([]) == ""
    end
  end
end
