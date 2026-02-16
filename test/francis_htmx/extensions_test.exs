defmodule FrancisHtmx.ExtensionsTest do
  use ExUnit.Case
  alias FrancisHtmx.Extensions

  describe "hx_ext/1" do
    test "generates hx-ext attribute for single string extension" do
      assert Extensions.hx_ext("sse") == ~s(hx-ext="sse")
    end

    test "generates hx-ext attribute for single atom extension" do
      assert Extensions.hx_ext(:sse) == ~s(hx-ext="sse")
    end

    test "converts underscores to hyphens for atom extensions" do
      assert Extensions.hx_ext(:response_targets) == ~s(hx-ext="response-targets")
    end

    test "generates hx-ext attribute for list of extensions" do
      result = Extensions.hx_ext(["sse", "ws"])
      assert result == ~s(hx-ext="sse,ws")
    end

    test "generates hx-ext attribute for mixed atom and string list" do
      result = Extensions.hx_ext([:sse, "ws", :response_targets])
      assert result == ~s(hx-ext="sse,ws,response-targets")
    end
  end

  describe "extension_scripts/1" do
    test "generates script tag for single extension" do
      result = Extensions.extension_scripts(:sse)
      assert result =~ ~s(<script src="https://unpkg.com/htmx-ext-sse@)
      assert result =~ ~s(sse.js"></script>)
    end

    test "generates script tags for multiple extensions" do
      result = Extensions.extension_scripts([:sse, :ws])
      assert result =~ ~s(htmx-ext-sse@)
      assert result =~ ~s(htmx-ext-ws@)
    end

    test "handles string extension names" do
      result = Extensions.extension_scripts("response-targets")
      assert result =~ ~s(htmx-ext-response-targets@)
    end

    test "returns custom URL for unknown extensions" do
      result = Extensions.extension_scripts("custom-extension")
      assert result == ~s(<script src="custom-extension"></script>)
    end
  end

  describe "get_extension_url/1" do
    test "returns CDN URL for known extension" do
      url = Extensions.get_extension_url(:sse)
      assert url =~ "https://unpkg.com/htmx-ext-sse@"
    end

    test "returns CDN URL for string extension name" do
      url = Extensions.get_extension_url("response-targets")
      assert url =~ "https://unpkg.com/htmx-ext-response-targets@"
    end

    test "returns input for unknown extension" do
      url = Extensions.get_extension_url("unknown-ext")
      assert url == "unknown-ext"
    end

    test "handles all core extensions" do
      extensions = [
        :head_support,
        :idiomorph,
        :preload,
        :response_targets,
        :sse,
        :ws
      ]

      for ext <- extensions do
        url = Extensions.get_extension_url(ext)
        assert url =~ "https://unpkg.com/"
      end
    end
  end
end
