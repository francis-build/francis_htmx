defmodule FrancisHtmx.Page do
  import FrancisHtmx.Headers, only: [htmx_request?: 1, history_restore_request?: 1]
  import Plug.Conn, only: [put_resp_content_type: 2, send_resp: 3]

  @moduledoc """
  Helpers for building Multi-Page Applications (MPA) with HTMX.

  Provides content negotiation between full-page and partial responses:
  - Direct URL access → full page (wrapped in layout)
  - HTMX request → partial content only
  - History restore → full page (browser back after cache expires)

  ## Layout Callback

  You provide your own layout via the `:layout` option. A layout function receives
  a map with `:content` and `:title` keys, and returns the full HTML page string.

  This follows the HTMX philosophy: you write your own HTML, the library only
  handles content negotiation.

      defp my_layout(assigns) do
        \"""
        <!DOCTYPE html>
        <html>
          <head><title>\#{assigns.title}</title>
            <script src="https://unpkg.com/htmx.org@2"></script>
          </head>
          <body hx-boost="true">
            <nav><a href="/">Home</a> <a href="/about">About</a></nav>
            <div id="main-content">\#{assigns.content}</div>
          </body>
        </html>
        \"""
      end

      render_page(conn, fn -> "<h1>Hello</h1>" end, layout: &my_layout/1, title: "Home")

  ## Default Layout

  When no `:layout` is provided, a minimal HTML shell is used with just
  `<html>`, `<head>`, `<body hx-boost="true">`, and a content div.

  ## Examples

      # With custom layout
      render_page(conn, fn -> "<h1>About</h1>" end, layout: &my_layout/1)

      # With default layout
      render_page(conn, fn -> "<h1>Hello</h1>" end, title: "My App")
  """

  @doc """
  Renders a page handling content negotiation between full and partial responses.

  ## Parameters

  - `conn` - The Plug connection
  - `content_fn` - Zero-arity function returning the page content HTML

  ## Options

  - `:layout` - Function that receives `%{content: String.t(), title: String.t()}` and returns full HTML page.
                 When omitted, a minimal default layout is used.
  - `:title` - Page title passed to the layout (default: "FrancisHTMX App")
  - `:target` - Content div ID (default: "main-content"), only used by default layout
  """
  def render_page(conn, content_fn, opts \\ []) do
    content = FrancisHtmx.rendered_to_string(content_fn.())

    html_body =
      if htmx_request?(conn) and not history_restore_request?(conn) do
        content
      else
        layout_fn = Keyword.get(opts, :layout)
        title = Keyword.get(opts, :title, "FrancisHTMX App")

        assigns = %{content: content, title: title}

        if layout_fn do
          layout_fn.(assigns)
        else
          default_layout(assigns, opts)
        end
      end

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html_body)
  end

  defp default_layout(%{content: content, title: title}, opts) do
    target = Keyword.get(opts, :target, "main-content")

    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <script src="https://unpkg.com/htmx.org@2"></script>
        <title>#{title}</title>
      </head>
      <body hx-boost="true">
        <div id="#{target}">
          #{content}
        </div>
      </body>
    </html>
    """
  end

  @doc """
  Macro that combines `get/2` and `render_page/3` into a single call.

  ## Examples

      route "/about", fn ->
        ~H\"""
        <h1>About Us</h1>
        \"""
      end, layout: &my_layout/1, title: "About"
  """
  defmacro route(path, content_fn, opts \\ []) do
    quote location: :keep do
      get(unquote(path), fn conn ->
        render_page(conn, unquote(content_fn), unquote(opts))
      end)
    end
  end
end
