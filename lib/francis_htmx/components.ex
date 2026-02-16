defmodule FrancisHtmx.Components do
  @moduledoc """
  Helper module for creating reusable HTMX components.

  This module provides utilities for building composable HTMX components
  that can be nested and reused throughout your application.

  ## Usage

      defmodule MyApp.Components do
        use FrancisHtmx
        import FrancisHtmx.Components

        def button(text, url, opts \\ []) do
          target = Keyword.get(opts, :target, "")
          swap = Keyword.get(opts, :swap, "innerHTML")

          assigns = %{text: text, url: url, target: target, swap: swap}

          ~H\"\"\"
          <button hx-get={@url} hx-target={@target} hx-swap={@swap}>
            {@text}
          </button>
          \"\"\"
        end

        def card(title, content) do
          assigns = %{title: title, content: content}

          ~H\"\"\"
          <div class="card">
            <h3>{@title}</h3>
            <div>{@content}</div>
          </div>
          \"\"\"
        end
      end

      defmodule MyApp do
        use Francis
        use FrancisHtmx
        alias MyApp.Components

        htmx(fn _conn ->
          ~H\"\"\"
          <div>
            \#{Components.button("Load Data", "/data", target: "#results")}
            <div id="results"></div>
          </div>
          \"\"\"
        end)
      end
  """

  @doc """
  Creates a wrapper component that can contain other components.

  ## Examples

      wrapper("main-content", "hx-get='/updates' hx-trigger='every 5s'", fn ->
        ~H\"\"\"
        <div>Inner content</div>
        \"\"\"
      end)
  """
  @spec wrapper(String.t(), String.t(), (() -> String.t())) :: String.t()
  def wrapper(id, attrs \\ "", content_fn) when is_function(content_fn, 0) do
    content = content_fn.()
    ~s(<div id="#{id}" #{attrs}>#{content}</div>)
  end

  @doc """
  Creates a fragment that can be swapped in via HTMX.

  This is useful for partial page updates and nested components.

  ## Examples

      fragment("user-list", fn ->
        ~H\"\"\"
        <ul>
          <li>User 1</li>
          <li>User 2</li>
        </ul>
        \"\"\"
      end)
  """
  @spec fragment(String.t(), (() -> String.t())) :: String.t()
  def fragment(id, content_fn) when is_function(content_fn, 0) do
    content = content_fn.()
    ~s(<div id="#{id}">#{content}</div>)
  end

  @doc """
  Renders content conditionally based on whether it's an HTMX request.

  ## Examples

      htmx_or_full(conn,
        htmx: fn -> ~H"<div>Partial</div>" end,
        full: fn -> ~H"<html>...</html>" end
      )
  """
  @spec htmx_or_full(Plug.Conn.t(), Keyword.t()) :: String.t()
  def htmx_or_full(conn, opts) do
    htmx_fn = Keyword.fetch!(opts, :htmx)
    full_fn = Keyword.fetch!(opts, :full)

    if FrancisHtmx.Headers.htmx_request?(conn) do
      htmx_fn.()
    else
      full_fn.()
    end
  end

end
