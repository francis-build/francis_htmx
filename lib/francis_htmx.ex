defmodule FrancisHtmx do
  @moduledoc """
  Provides a macro to render htmx content by bundling htmx.js inline.
  Also provides a sigil to render EEx content similar to ~H from Phoenix.LiveView.

  The htmx.js library is bundled and inlined in the HTML output, eliminating
  the need for CDN dependencies. Use `mix francis_htmx.update` to download
  a specific version of htmx.

  Usage:
  ```elixir
    defmodule Example do
      use Francis
      use FrancisHtmx, title: "My App"

      htmx(fn _conn ->
        assigns = %{}
        ~E\"\"\"
        <style>
          .smooth {   transition: all 1s ease-in; font-size: 8rem; }
        </style>
        <div hx-get="/colors" hx-trigger="every 1s">
          <p id="color-demo" class="smooth">Color Swap Demo</p>
        </div>
        \"\"\"
      end)

      get("/colors", fn _ ->
        new_color = 3 |> :crypto.strong_rand_bytes() |> Base.encode16() |> then(&"\#{&1}")
        assigns = %{new_color: new_color}

        ~E\"\"\"
        <p id="color-demo" class="smooth" style="<%= "color:\#{@new_color}"%>">
        Color Swap Demo
        </p>
        \"\"\"
      end)
    end
  ```

  In this scenario we are serving an HTML page with the htmx.js library inlined
  and the root content given by htmx/1.
  """

  @htmx_js_path Path.join([__DIR__, "..", "priv", "static", "htmx.min.js"])
  @external_resource @htmx_js_path
  @htmx_js File.read!(@htmx_js_path)

  defmacro __using__(opts) do
    quote do
      import FrancisHtmx
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
  Renders htmx content by inlining htmx.js and rendering binary content.
  """
  @spec htmx((Plug.Conn.t() -> binary())) :: Macro.t()
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
  Renders htmx content by inlining htmx.js and rendering binary content.
  """
  @spec htmx((Plug.Conn.t() -> binary()), Keyword.t()) :: Macro.t()
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
  Provides a sigil to render EEx content similar to ~H from Phoenix.LiveView

  If a variable named "assigns" doesn't exist, it will be set to an empty map.
  """
  @spec sigil_E(String.t(), Keyword.t()) :: Macro.t()
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
