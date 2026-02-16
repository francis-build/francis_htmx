defmodule FrancisHtmx.Navigation do
  @moduledoc """
  Helper module for building multi-page HTMX applications with smooth navigation.

  This module provides utilities for creating single-page-app-like experiences
  with HTMX's boost feature and proper URL management.

  ## Usage

      use FrancisHtmx
      import FrancisHtmx.Navigation

      get("/page1", fn conn ->
        page(conn, "Page 1", fn ->
          ~H\"\"\"
          <h1>Page 1</h1>
          <a href="/page2">Go to Page 2</a>
          \"\"\"
        end)
      end)

      get("/page2", fn conn ->
        page(conn, "Page 2", fn ->
          ~H\"\"\"
          <h1>Page 2</h1>
          <a href="/page1">Back to Page 1</a>
          \"\"\"
        end)
      end)
  """

  @doc """
  Renders a page that works in both full-page and HTMX contexts.

  Automatically handles URL updates and provides consistent navigation.

  ## Examples

      page(conn, "Home", fn ->
        ~H\"\"\"
        <h1>Welcome</h1>
        <a href="/about">About</a>
        \"\"\"
      end)

      page(conn, "Dashboard", fn ->
        ~H\"\"\"
        <div id="dashboard">
          <h1>Dashboard</h1>
        </div>
        \"\"\"
      end, push_url: true)
  """
  @spec page(Plug.Conn.t(), String.t(), (() -> String.t()), Keyword.t()) :: Plug.Conn.t()
  def page(conn, title, content_fn, opts \\ []) when is_function(content_fn, 0) do
    content = content_fn.()
    push_url = Keyword.get(opts, :push_url, true)
    layout_fn = Keyword.get(opts, :layout)

    if FrancisHtmx.Headers.htmx_request?(conn) do
      conn = if push_url, do: FrancisHtmx.Headers.push_url(conn, true), else: conn

      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, content)
    else
      full_page =
        if layout_fn do
          layout_fn.(title, content)
        else
          default_layout(title, content, opts)
        end

      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, full_page)
    end
  end

  @doc """
  Creates a navigation link that works with HTMX boost.

  ## Examples

      nav_link("/home", "Home")
      #=> ~s(<a href="/home" hx-boost="true" hx-push-url="true">Home</a>)

      nav_link("/profile", "Profile", class: "nav-item active")
      #=> ~s(<a href="/profile" class="nav-item active" hx-boost="true" hx-push-url="true">Profile</a>)

      nav_link("/delete", "Delete", boost: false, confirm: "Are you sure?")
      #=> ~s(<a href="/delete" hx-confirm="Are you sure?">Delete</a>)
  """
  @spec nav_link(String.t(), String.t(), Keyword.t()) :: String.t()
  def nav_link(url, text, opts \\ []) do
    boost = Keyword.get(opts, :boost, true)
    push_url = Keyword.get(opts, :push_url, true)
    confirm = Keyword.get(opts, :confirm)
    class = Keyword.get(opts, :class, "")

    attrs =
      []
      |> add_attr("class", class, class != "")
      |> add_attr("hx-boost", "true", boost)
      |> add_attr("hx-push-url", "true", boost && push_url)
      |> add_attr("hx-confirm", confirm, confirm != nil)
      |> Enum.join(" ")

    ~s(<a href="#{url}" #{attrs}>#{text}</a>)
  end

  @doc """
  Creates a navigation menu with HTMX-enabled links.

  ## Examples

      nav_menu([
        {"/", "Home"},
        {"/about", "About"},
        {"/contact", "Contact"}
      ])

      nav_menu([
        {"/", "Home", active: true},
        {"/about", "About"},
        {"/contact", "Contact"}
      ], class: "nav-item", active_class: "active")
  """
  @spec nav_menu(list(tuple()), Keyword.t()) :: String.t()
  def nav_menu(items, opts \\ []) do
    item_class = Keyword.get(opts, :class, "")
    active_class = Keyword.get(opts, :active_class, "active")
    container_class = Keyword.get(opts, :container_class, "nav")

    links =
      items
      |> Enum.map(fn
        {url, text} ->
          nav_link(url, text, class: item_class)

        {url, text, item_opts} ->
          is_active = Keyword.get(item_opts, :active, false)

          class =
            if is_active && active_class != "" do
              "#{item_class} #{active_class}"
            else
              item_class
            end

          nav_link(url, text, class: class)
      end)
      |> Enum.join("\n    ")

    ~s(<nav class="#{container_class}">\n    #{links}\n  </nav>)
  end

  @doc """
  Creates a breadcrumb navigation component.

  ## Examples

      breadcrumbs([
        {"/", "Home"},
        {"/products", "Products"},
        {nil, "Details"}
      ])

      # With custom target for SPA navigation
      breadcrumbs([...], target: "#main-content")
  """
  @spec breadcrumbs(list(tuple()), Keyword.t()) :: String.t()
  def breadcrumbs(items, opts \\ []) do
    separator = Keyword.get(opts, :separator, "/")
    container_class = Keyword.get(opts, :container_class, "breadcrumbs")
    item_class = Keyword.get(opts, :item_class, "breadcrumb-item")
    target = Keyword.get(opts, :target)

    crumbs =
      items
      |> Enum.map(fn
        {nil, text} ->
          ~s(<span class="#{item_class}">#{text}</span>)

        {url, text} ->
          link =
            if target do
              ~s(<a href="#{url}" hx-get="#{url}" hx-target="#{target}" hx-swap="innerHTML" hx-push-url="true">#{text}</a>)
            else
              nav_link(url, text)
            end

          ~s(<span class="#{item_class}">#{link}</span>)
      end)
      |> Enum.intersperse(~s(<span class="breadcrumb-separator">#{separator}</span>))
      |> Enum.join("\n    ")

    ~s(<div class="#{container_class}">\n    #{crumbs}\n  </div>)
  end

  @doc """
  Creates a back button that uses browser history.

  ## Examples

      back_button("Go Back")
      #=> ~s(<button onclick="history.back()">Go Back</button>)

      back_button("Back", class: "btn btn-secondary")
      #=> ~s(<button class="btn btn-secondary" onclick="history.back()">Back</button>)
  """
  @spec back_button(String.t(), Keyword.t()) :: String.t()
  def back_button(text \\ "Back", opts \\ []) do
    class = Keyword.get(opts, :class, "")

    class_attr =
      if class != "" do
        " class=\"#{class}\""
      else
        ""
      end

    "<button#{class_attr} onclick=\"history.back()\">#{text}</button>"
  end

  @doc """
  Creates a redirect helper that works with HTMX.

  For HTMX requests, uses HX-Location header.
  For regular requests, uses standard HTTP redirect.

  ## Examples

      redirect_to(conn, "/login")

      redirect_to(conn, "/dashboard", status: 302)
  """
  @spec redirect_to(Plug.Conn.t(), String.t(), Keyword.t()) :: Plug.Conn.t()
  def redirect_to(conn, url, opts \\ []) do
    status = Keyword.get(opts, :status, 302)

    if FrancisHtmx.Headers.htmx_request?(conn) do
      conn
      |> FrancisHtmx.Headers.location(url)
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, "")
    else
      conn
      |> Plug.Conn.put_resp_header("location", url)
      |> Plug.Conn.send_resp(status, "")
    end
  end

  @doc """
  Creates a paginated navigation component.

  ## Examples

      pagination(conn, page: 2, total_pages: 10, path: "/products")

      # With custom target for SPA navigation
      pagination(conn, page: 2, total_pages: 10, path: "/products", target: "#main-content")
  """
  @spec pagination(Plug.Conn.t(), Keyword.t()) :: String.t()
  def pagination(_conn, opts) do
    current_page = Keyword.fetch!(opts, :page)
    total_pages = Keyword.fetch!(opts, :total_pages)
    path = Keyword.fetch!(opts, :path)
    max_links = Keyword.get(opts, :max_links, 5)
    target = Keyword.get(opts, :target)

    has_prev = current_page > 1
    has_next = current_page < total_pages

    start_page = max(1, current_page - div(max_links, 2))
    end_page = min(total_pages, start_page + max_links - 1)
    start_page = max(1, end_page - max_links + 1)

    # Helper to create link with optional target
    make_link = fn url, text ->
      if target do
        ~s(<a href="#{url}" hx-get="#{url}" hx-target="#{target}" hx-swap="innerHTML" hx-push-url="true">#{text}</a>)
      else
        nav_link(url, text)
      end
    end

    prev_link =
      if has_prev do
        ~s(<li>#{make_link.("#{path}?page=#{current_page - 1}", "Previous")}</li>)
      else
        ~s(<li class="disabled"><span>Previous</span></li>)
      end

    next_link =
      if has_next do
        ~s(<li>#{make_link.("#{path}?page=#{current_page + 1}", "Next")}</li>)
      else
        ~s(<li class="disabled"><span>Next</span></li>)
      end

    page_links =
      start_page..end_page
      |> Enum.map(fn page ->
        if page == current_page do
          ~s(<li class="active"><span>#{page}</span></li>)
        else
          ~s(<li>#{make_link.("#{path}?page=#{page}", "#{page}")}</li>)
        end
      end)
      |> Enum.join("\n      ")

    """
    <ul class="pagination">
      #{prev_link}
      #{page_links}
      #{next_link}
    </ul>
    """
  end

  defp default_layout(title, content, opts) do
    head_content = Keyword.get(opts, :head, "")
    version = Keyword.get(opts, :version, "2")
    main_id = Keyword.get(opts, :main_id, "main")

    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{title}</title>
        <script src="https://unpkg.com/htmx.org@#{version}"></script>
        #{head_content}
      </head>
      <body hx-boost="true">
        <div id="#{main_id}">
          #{content}
        </div>
      </body>
    </html>
    """
  end

  defp add_attr(attrs, _name, _value, false), do: attrs
  defp add_attr(attrs, name, value, true), do: attrs ++ [~s(#{name}="#{value}")]
end
