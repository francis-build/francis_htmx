defmodule FrancisHtmx do
  @moduledoc """
  Provides a macro to render htmx content by loading htmx.js.
  Uses Phoenix's `~H` sigil (HEEx) for templating with full component support.

  Usage:
  ```elixir
    defmodule Example do
      use Francis
      use FrancisHtmx

      htmx(fn _conn ->
        assigns = %{}
        ~H\"\"\"
        <style>
          .smooth {   transition: all 1s ease-in; font-size: 8rem; }
        </style>
        <div hx-get="/colors" hx-trigger="every 1s">
          <p id="color-demo" class="smooth">Color Swap Demo</p>
        </div>
        \"\"\"
      end)

      get("/colors", fn _ ->
        assigns = %{new_color: "red"}

        ~H\"\"\"
        <p id="color-demo" class="smooth" style={"color:\#{@new_color}"}>
        Color Swap Demo
        </p>
        \"\"\"
      end)
    end
  ```

  In this scenario we are loading serving an HTML that has the htmx.js library loaded and serves the root content given by htmx/1
  """

  defmacro __using__(opts) do
    quote do
      import Phoenix.Component, only: [sigil_H: 2, assign: 2, assign: 3]
      import Phoenix.HTML
      import FrancisHtmx.Page, only: [render_page: 2, render_page: 3, route: 2, route: 3]
      import unquote(__MODULE__), only: [htmx: 1, htmx: 2]

      checker = ~r/^(\d+\.)?(\d+\.)?(\*|\d+)$/
      version = Application.compile_env(:francis_htmx, :version, "2")
      version = Keyword.get(unquote(opts), :version, version)
      title = Keyword.get(unquote(opts), :title, "")
      head = Keyword.get(unquote(opts), :head, "")

      if !Regex.match?(checker, version) do
        raise "Invalid version format. Expected format is 'x.y.z' or 'x.y.*'. Got: '#{version}'"
      end

      Module.put_attribute(__MODULE__, :htmx_version, version)
      Module.put_attribute(__MODULE__, :htmx_title, title)
      Module.put_attribute(__MODULE__, :htmx_head, head)
      Module.register_attribute(__MODULE__, :htmx_version, accumulate: false)
      Module.register_attribute(__MODULE__, :htmx_title, accumulate: false)
      Module.register_attribute(__MODULE__, :htmx_head, accumulate: false)
    end
  end

  @doc """
  Converts a `~H` rendered result or a string to a plain HTML string.

  This is useful when you need to pass `~H` output to functions that expect strings,
  such as layout functions or string interpolation.

  ## Examples

      rendered_to_string(~H"<div>Hello</div>")
      #=> "<div>Hello</div>"

      rendered_to_string("<div>Hello</div>")
      #=> "<div>Hello</div>"
  """
  def rendered_to_string(content) when is_binary(content), do: content

  def rendered_to_string(%Phoenix.LiveView.Rendered{} = rendered) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  def rendered_to_string({:safe, iodata}) do
    IO.iodata_to_binary(iodata)
  end

  @doc """
  Renders htmx content by loading htmx.js and rendering binary content.
  """
  @spec htmx((Plug.Conn.t() -> binary())) :: Macro.t()
  defmacro htmx(content) do
    quote location: :keep do
      get("/", fn conn ->
        head = FrancisHtmx.rendered_to_string(@htmx_head)
        body = FrancisHtmx.rendered_to_string(unquote(content).(conn))

        html(conn, """
        <!DOCTYPE html>
        <html>
          <head>
            #{head}
            <script src="https://unpkg.com/htmx.org@#{@htmx_version}"></script>
            <title>#{@htmx_title}</title>
          </head>
          <body>
            #{body}
          </body>
        </html>
        """)
      end)
    end
  end

  @doc """
  Renders htmx content by loading htmx.js and rendering binary content.

  ## Options

  - `:title` - Page title (overrides default)
  - `:head` - Additional head content (overrides default)
  - `:extensions` - List of HTMX extensions to load (atom or string)
  - `:body_attrs` - Additional attributes for the body tag

  ## Examples

      htmx(fn _conn -> ~H"<div>Content</div>" end,
        title: "My Page",
        extensions: [:sse, :ws],
        body_attrs: ~s(hx-ext="sse")
      )
  """
  @spec htmx((Plug.Conn.t() -> binary()), Keyword.t()) :: Macro.t()
  defmacro htmx(content, opts) do
    quote location: :keep do
      get("/", fn conn ->
        title = Keyword.get(unquote(opts), :title, @htmx_title)
        head = FrancisHtmx.rendered_to_string(Keyword.get(unquote(opts), :head, @htmx_head))
        extensions = Keyword.get(unquote(opts), :extensions, [])
        body_attrs = Keyword.get(unquote(opts), :body_attrs, "")
        body = FrancisHtmx.rendered_to_string(unquote(content).(conn))

        extension_scripts =
          if extensions != [] do
            FrancisHtmx.Extensions.extension_scripts(extensions)
          else
            ""
          end

        html(conn, """
        <!DOCTYPE html>
        <html>
          <head>
            #{head}
            <script src="https://unpkg.com/htmx.org@#{@htmx_version}"></script>
            #{extension_scripts}
            <title>#{title}</title>
          </head>
          <body #{body_attrs}>
            #{body}
          </body>
        </html>
        """)
      end)
    end
  end
end
