defmodule FrancisHtmx.Extensions do
  @moduledoc """
  Helper module for working with HTMX extensions.

  HTMX supports extensions to augment its core hypermedia infrastructure.
  This module provides functions to easily load and configure extensions.

  ## Usage

      use FrancisHtmx
      import FrancisHtmx.Extensions

      htmx(
        fn _conn ->
          ~H\"\"\"
          <div \#{hx_ext("response-targets")}>
            <button hx-get="/data">Load</button>
          </div>
          \"\"\"
        end,
        extensions: ["response-targets", "preload"]
      )

  ## Core Extensions

  - `:head_support` - Merges head tag information in htmx requests
  - `:idiomorph` - Morphing swap strategy using the idiomorph library
  - `:preload` - Preloads HTML fragments into browser cache
  - `:response_targets` - Different target elements based on response codes
  - `:sse` - Server Sent Events support directly from HTML
  - `:ws` - WebSockets bi-directional communication

  ## Community Extensions

  See https://extensions.htmx.org for the full list of community extensions.
  """

  @extension_urls %{
    head_support: "https://unpkg.com/htmx-ext-head-support@2.0.1/head-support.js",
    idiomorph: "https://unpkg.com/idiomorph@0.3.0/dist/idiomorph-ext.min.js",
    preload: "https://unpkg.com/htmx-ext-preload@2.0.1/preload.js",
    response_targets: "https://unpkg.com/htmx-ext-response-targets@2.0.0/response-targets.js",
    sse: "https://unpkg.com/htmx-ext-sse@2.2.2/sse.js",
    ws: "https://unpkg.com/htmx-ext-ws@2.0.1/ws.js",
    class_tools: "https://unpkg.com/htmx-ext-class-tools@2.0.1/class-tools.js",
    loading_states: "https://unpkg.com/htmx-ext-loading-states@2.0.0/loading-states.js",
    debug: "https://unpkg.com/htmx-ext-debug@2.0.1/debug.js",
    multi_swap: "https://unpkg.com/htmx-ext-multi-swap@2.0.0/multi-swap.js",
    path_params: "https://unpkg.com/htmx-ext-path-params@2.0.0/path-params.js",
    client_side_templates:
      "https://unpkg.com/htmx-ext-client-side-templates@2.0.0/client-side-templates.js",
    json_enc: "https://unpkg.com/htmx-ext-json-enc@2.0.1/json-enc.js"
  }

  @doc """
  Generates the hx-ext attribute value for one or more extensions.

  ## Examples

      hx_ext("sse")
      #=> ~s(hx-ext="sse")

      hx_ext(["response-targets", "preload"])
      #=> ~s(hx-ext="response-targets,preload")

      hx_ext(:idiomorph)
      #=> ~s(hx-ext="idiomorph")
  """
  @spec hx_ext(String.t() | atom() | list(String.t() | atom())) :: String.t()
  def hx_ext(extension) when is_binary(extension) or is_atom(extension) do
    ext_name = normalize_extension_name(extension)
    ~s(hx-ext="#{ext_name}")
  end

  def hx_ext(extensions) when is_list(extensions) do
    ext_names =
      extensions
      |> Enum.map(&normalize_extension_name/1)
      |> Enum.join(",")

    ~s(hx-ext="#{ext_names}")
  end

  @doc """
  Generates script tags to load the specified extensions.

  ## Examples

      extension_scripts([:sse, :ws])
      #=> \"\"\"
      <script src="https://unpkg.com/htmx-ext-sse@2.2.2/sse.js"></script>
      <script src="https://unpkg.com/htmx-ext-ws@2.0.1/ws.js"></script>
      \"\"\"

      extension_scripts("response-targets")
      #=> ~s(<script src="https://unpkg.com/htmx-ext-response-targets@2.0.0/response-targets.js"></script>)
  """
  @spec extension_scripts(String.t() | atom() | list(String.t() | atom())) :: String.t()
  def extension_scripts(extension) when is_binary(extension) or is_atom(extension) do
    extension_scripts([extension])
  end

  def extension_scripts(extensions) when is_list(extensions) do
    extensions
    |> Enum.map(&get_extension_url/1)
    |> Enum.map(&~s(<script src="#{&1}"></script>))
    |> Enum.join("\n    ")
  end

  @doc """
  Gets the CDN URL for a specific extension.

  ## Examples

      get_extension_url(:sse)
      #=> "https://unpkg.com/htmx-ext-sse@2.2.2/sse.js"

      get_extension_url("response-targets")
      #=> "https://unpkg.com/htmx-ext-response-targets@2.0.0/response-targets.js"

      get_extension_url("custom-extension")
      #=> "custom-extension"
  """
  @spec get_extension_url(String.t() | atom()) :: String.t()
  def get_extension_url(extension) when is_binary(extension) or is_atom(extension) do
    key = normalize_extension_key(extension)
    Map.get(@extension_urls, key, to_string(extension))
  end

  defp normalize_extension_name(extension) when is_atom(extension) do
    extension |> Atom.to_string() |> String.replace("_", "-")
  end

  defp normalize_extension_name(extension) when is_binary(extension), do: extension

  defp normalize_extension_key(extension) when is_binary(extension) do
    extension
    |> String.replace("-", "_")
    |> String.to_atom()
  end

  defp normalize_extension_key(extension) when is_atom(extension), do: extension
end
