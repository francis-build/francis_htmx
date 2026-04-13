defmodule FrancisHtmx do
  @moduledoc """
  HTMX integration for the Francis web framework.

  Provides the `htmx` macro that generates a full HTML page with htmx.js bundled
  inline (no CDN dependency), and the `~E` sigil for EEx templating with `@assigns`
  support.

  ## Setup

      defmodule MyApp do
        use Francis
        use FrancisHtmx, title: "My App"
      end

  ## Options

    * `:title` — HTML page title, escaped via `Francis.HTML.escape/1` (default: `""`)
    * `:head` — additional HTML injected into `<head>`, e.g. stylesheets or scripts (default: `""`)

  ## Example

      defmodule Example do
        use Francis
        use FrancisHtmx, title: "Color Demo"

        htmx(fn _conn ->
          ~E\"\"\"
          <div hx-get="/colors" hx-trigger="every 1s">
            <p id="color-demo">Color Swap Demo</p>
          </div>
          \"\"\"
        end)

        get("/colors", fn _ ->
          new_color = 3 |> :crypto.strong_rand_bytes() |> Base.encode16() |> then(&"\#\#{&1}")
          assigns = %{new_color: new_color}

          ~E\"\"\"
          <p id="color-demo" style="<%= "color:\#{@new_color}" %>">Color Swap Demo</p>
          \"\"\"
        end)
      end

  ## Updating htmx

  The bundled htmx.js version can be updated via the included Mix task:

      mix francis_htmx.update          # downloads the latest release
      mix francis_htmx.update 2.0.4    # downloads a specific version

  After updating, recompile with `mix compile --force` to pick up the new version.
  """

  @htmx_js_path Path.join([__DIR__, "..", "priv", "static", "htmx.min.js"])
  @external_resource @htmx_js_path
  @htmx_js File.read!(@htmx_js_path)

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__), only: [htmx: 1, htmx: 2, sigil_E: 2]
      import Phoenix.HTML

      if Keyword.has_key?(unquote(opts), :version) do
        IO.warn(
          "The :version option for FrancisHtmx is deprecated. " <>
            "htmx is now bundled inline. Use `mix francis_htmx.update VERSION` to change the bundled version."
        )
      end

      title = Keyword.get(unquote(opts), :title, "")
      head = Keyword.get(unquote(opts), :head, "")

      Module.put_attribute(__MODULE__, :htmx_title, title)
      Module.put_attribute(__MODULE__, :htmx_head, head)
      Module.register_attribute(__MODULE__, :htmx_title, accumulate: false)
      Module.register_attribute(__MODULE__, :htmx_head, accumulate: false)
    end
  end

  @doc """
  Defines a `GET "/"` route that serves a full HTML page with htmx.js inlined.

  The `content` function receives the `Plug.Conn` and must return an HTML binary
  (typically via the `~E` sigil). The generated page includes proper HTML5 structure,
  the bundled htmx.js, and any head/title configured via `use FrancisHtmx`.

  ## Example

      htmx(fn _conn ->
        ~E\"\"\"
        <div hx-get="/api" hx-trigger="load">Loading...</div>
        \"\"\"
      end)
  """
  defmacro htmx(content) do
    htmx_js = @htmx_js

    quote location: :keep do
      get("/", fn conn ->
        html(conn, """
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            #{@htmx_head}
            <script>#{unquote(htmx_js)}</script>
            <title>#{Francis.HTML.escape(@htmx_title)}</title>
          </head>
          <body>
            #{unquote(content).(conn)}
          </body>
        </html>
        """)
      end)
    end
  end

  @doc """
  Defines a `GET "/"` route with per-page title and head overrides.

  Works like `htmx/1` but accepts a keyword list to override the `:title` and `:head`
  values set in `use FrancisHtmx`.

  ## Options

    * `:title` — overrides the page `<title>` (escaped via `Francis.HTML.escape/1`)
    * `:head` — overrides the extra `<head>` content (scripts, stylesheets, etc.)

  ## Example

      htmx(
        fn _conn ->
          ~E\"\"\"
          <h1>Dashboard</h1>
          \"\"\"
        end,
        title: "Dashboard",
        head: ~E\"\"\"<link href="/dashboard.css" rel="stylesheet">\"\"\"
      )
  """
  defmacro htmx(content, opts) do
    htmx_js = @htmx_js

    quote location: :keep do
      get("/", fn conn ->
        title = Keyword.get(unquote(opts), :title, @htmx_title)
        head = Keyword.get(unquote(opts), :head, @htmx_head)

        html(conn, """
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            #{head}
            <script>#{unquote(htmx_js)}</script>
            <title>#{Francis.HTML.escape(title)}</title>
          </head>
          <body>
            #{unquote(content).(conn)}
          </body>
        </html>
        """)
      end)
    end
  end

  @doc """
  Renders an EEx template string with `@assigns` support, similar to Phoenix LiveView's `~H`.

  Uses `Phoenix.HTML.Engine` for safe HTML rendering — interpolated values are
  automatically escaped. If no `assigns` variable exists in the calling scope,
  an empty map is used.

  ## Examples

      # With explicit assigns
      assigns = %{name: "World"}
      ~E\"\"\"
      <p>Hello, <%= @name %>!</p>
      \"\"\"

      # Without assigns (empty map used automatically)
      ~E\"\"\"
      <p>Static content</p>
      \"\"\"
  """
  defmacro sigil_E(content, _opts \\ []) do
    if Macro.Env.has_var?(__CALLER__, {:assigns, nil}) do
      quote location: :keep do
        content =
          EEx.eval_string(unquote(content), [assigns: var!(assigns)], engine: Phoenix.HTML.Engine)

        content
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
      end
    else
      quote location: :keep do
        assigns = %{}

        content =
          EEx.eval_string(unquote(content), [assigns: assigns], engine: Phoenix.HTML.Engine)

        content
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
      end
    end
  end
end
