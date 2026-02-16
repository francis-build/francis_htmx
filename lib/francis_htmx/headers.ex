defmodule FrancisHtmx.Headers do
  @moduledoc """
  Helper module for working with HTMX request and response headers.

  HTMX uses custom headers for communication between client and server.
  This module provides functions to read request headers and set response headers.

  ## Usage

      use Francis
      import FrancisHtmx.Headers

      get("/data", fn conn ->
        if htmx_request?(conn) do
          target = get_target(conn)
          # Return partial HTML
          conn
          |> trigger("itemAdded")
          |> html("<div>New item</div>")
        else
          # Return full page
          html(conn, "<html>...</html>")
        end
      end)

  ## Request Headers

  HTMX includes several headers in requests:
  - `HX-Request`: Always "true" for htmx requests
  - `HX-Trigger`: ID of the element that triggered the request
  - `HX-Target`: ID of the target element
  - `HX-Current-URL`: Current URL in the browser
  - `HX-Prompt`: User response to prompt

  ## Response Headers

  HTMX recognizes several response headers:
  - `HX-Location`: Client-side redirect without page reload
  - `HX-Push-Url`: Push new URL to browser history
  - `HX-Redirect`: Full page redirect
  - `HX-Refresh`: Trigger full page refresh
  - `HX-Trigger`: Trigger client-side events
  """

  @doc """
  Checks if the request was initiated by HTMX.

  ## Examples

      htmx_request?(conn)
      #=> true
  """
  @spec htmx_request?(Plug.Conn.t()) :: boolean()
  def htmx_request?(conn) do
    case Plug.Conn.get_req_header(conn, "hx-request") do
      ["true"] -> true
      _ -> false
    end
  end

  @doc """
  Gets the ID of the element that triggered the request.

  ## Examples

      get_trigger(conn)
      #=> "submit-btn"
  """
  @spec get_trigger(Plug.Conn.t()) :: String.t() | nil
  def get_trigger(conn) do
    case Plug.Conn.get_req_header(conn, "hx-trigger") do
      [trigger] -> trigger
      _ -> nil
    end
  end

  @doc """
  Gets the name attribute of the element that triggered the request.

  ## Examples

      get_trigger_name(conn)
      #=> "submit"
  """
  @spec get_trigger_name(Plug.Conn.t()) :: String.t() | nil
  def get_trigger_name(conn) do
    case Plug.Conn.get_req_header(conn, "hx-trigger-name") do
      [name] -> name
      _ -> nil
    end
  end

  @doc """
  Gets the ID of the target element.

  ## Examples

      get_target(conn)
      #=> "results"
  """
  @spec get_target(Plug.Conn.t()) :: String.t() | nil
  def get_target(conn) do
    case Plug.Conn.get_req_header(conn, "hx-target") do
      [target] -> target
      _ -> nil
    end
  end

  @doc """
  Gets the current URL from the browser.

  ## Examples

      get_current_url(conn)
      #=> "https://example.com/page"
  """
  @spec get_current_url(Plug.Conn.t()) :: String.t() | nil
  def get_current_url(conn) do
    case Plug.Conn.get_req_header(conn, "hx-current-url") do
      [url] -> url
      _ -> nil
    end
  end

  @doc """
  Gets the user's response to a prompt.

  ## Examples

      get_prompt(conn)
      #=> "User input"
  """
  @spec get_prompt(Plug.Conn.t()) :: String.t() | nil
  def get_prompt(conn) do
    case Plug.Conn.get_req_header(conn, "hx-prompt") do
      [prompt] -> prompt
      _ -> nil
    end
  end

  @doc """
  Checks if the request is a history restore request.

  ## Examples

      history_restore_request?(conn)
      #=> false
  """
  @spec history_restore_request?(Plug.Conn.t()) :: boolean()
  def history_restore_request?(conn) do
    case Plug.Conn.get_req_header(conn, "hx-history-restore-request") do
      ["true"] -> true
      _ -> false
    end
  end

  @doc """
  Checks if the request was boosted.

  ## Examples

      boosted?(conn)
      #=> false
  """
  @spec boosted?(Plug.Conn.t()) :: boolean()
  def boosted?(conn) do
    case Plug.Conn.get_req_header(conn, "hx-boosted") do
      ["true"] -> true
      _ -> false
    end
  end

  @doc """
  Performs a client-side redirect without a full page reload.

  ## Examples

      conn
      |> location("/new-page")
      |> html("<div>Content</div>")
  """
  @spec location(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def location(conn, url) when is_binary(url) do
    Plug.Conn.put_resp_header(conn, "hx-location", url)
  end

  @doc """
  Performs a client-side redirect with additional options.

  ## Examples

      conn
      |> location("/new-page", target: "#main", swap: "outerHTML")
      |> html("<div>Content</div>")
  """
  @spec location(Plug.Conn.t(), String.t(), Keyword.t()) :: Plug.Conn.t()
  def location(conn, url, opts) when is_binary(url) and is_list(opts) do
    location_json =
      opts
      |> Keyword.put(:path, url)
      |> Enum.into(%{})
      |> Jason.encode!()

    Plug.Conn.put_resp_header(conn, "hx-location", location_json)
  end

  @doc """
  Pushes a new URL into the browser history stack.

  ## Examples

      conn
      |> push_url("/new-url")
      |> html("<div>Content</div>")
  """
  @spec push_url(Plug.Conn.t(), String.t() | boolean()) :: Plug.Conn.t()
  def push_url(conn, url) when is_binary(url) or is_boolean(url) do
    Plug.Conn.put_resp_header(conn, "hx-push-url", to_string(url))
  end

  @doc """
  Replaces the current URL in the browser location bar.

  ## Examples

      conn
      |> replace_url("/updated-url")
      |> html("<div>Content</div>")
  """
  @spec replace_url(Plug.Conn.t(), String.t() | boolean()) :: Plug.Conn.t()
  def replace_url(conn, url) when is_binary(url) or is_boolean(url) do
    Plug.Conn.put_resp_header(conn, "hx-replace-url", to_string(url))
  end

  @doc """
  Triggers a full page redirect.

  ## Examples

      conn
      |> hx_redirect("/login")
  """
  @spec hx_redirect(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def hx_redirect(conn, url) when is_binary(url) do
    Plug.Conn.put_resp_header(conn, "hx-redirect", url)
  end

  @doc """
  Triggers a full page refresh.

  ## Examples

      conn
      |> refresh()
      |> html("")
  """
  @spec refresh(Plug.Conn.t()) :: Plug.Conn.t()
  def refresh(conn) do
    Plug.Conn.put_resp_header(conn, "hx-refresh", "true")
  end

  @doc """
  Changes the target of the content update.

  ## Examples

      conn
      |> retarget("#different-div")
      |> html("<div>Content</div>")
  """
  @spec retarget(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def retarget(conn, selector) when is_binary(selector) do
    Plug.Conn.put_resp_header(conn, "hx-retarget", selector)
  end

  @doc """
  Changes the swap behavior.

  ## Examples

      conn
      |> reswap("outerHTML")
      |> html("<div>Content</div>")
  """
  @spec reswap(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def reswap(conn, strategy) when is_binary(strategy) do
    Plug.Conn.put_resp_header(conn, "hx-reswap", strategy)
  end

  @doc """
  Selects a part of the response to swap.

  ## Examples

      conn
      |> reselect("#content")
      |> html("<html>...</html>")
  """
  @spec reselect(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def reselect(conn, selector) when is_binary(selector) do
    Plug.Conn.put_resp_header(conn, "hx-reselect", selector)
  end

  @doc """
  Triggers client-side events immediately after receiving the response.

  ## Examples

      conn
      |> trigger("itemAdded")
      |> html("<div>Item</div>")

      conn
      |> trigger("itemAdded", %{id: 123})
      |> html("<div>Item</div>")

      conn
      |> trigger(["event1", "event2"])
      |> html("<div>Content</div>")
  """
  @spec trigger(Plug.Conn.t(), String.t() | list(String.t())) :: Plug.Conn.t()
  def trigger(conn, event) when is_binary(event) do
    Plug.Conn.put_resp_header(conn, "hx-trigger", event)
  end

  def trigger(conn, events) when is_list(events) do
    Plug.Conn.put_resp_header(conn, "hx-trigger", Enum.join(events, ", "))
  end

  @spec trigger(Plug.Conn.t(), String.t(), map()) :: Plug.Conn.t()
  def trigger(conn, event, detail) when is_binary(event) and is_map(detail) do
    trigger_json = Jason.encode!(%{event => detail})
    Plug.Conn.put_resp_header(conn, "hx-trigger", trigger_json)
  end

  @doc """
  Triggers client-side events after the swap step.

  ## Examples

      conn
      |> trigger_after_swap("swapped")
      |> html("<div>Content</div>")
  """
  @spec trigger_after_swap(Plug.Conn.t(), String.t() | list(String.t())) :: Plug.Conn.t()
  def trigger_after_swap(conn, event) when is_binary(event) do
    Plug.Conn.put_resp_header(conn, "hx-trigger-after-swap", event)
  end

  def trigger_after_swap(conn, events) when is_list(events) do
    Plug.Conn.put_resp_header(conn, "hx-trigger-after-swap", Enum.join(events, ", "))
  end

  @spec trigger_after_swap(Plug.Conn.t(), String.t(), map()) :: Plug.Conn.t()
  def trigger_after_swap(conn, event, detail) when is_binary(event) and is_map(detail) do
    trigger_json = Jason.encode!(%{event => detail})
    Plug.Conn.put_resp_header(conn, "hx-trigger-after-swap", trigger_json)
  end

  @doc """
  Triggers client-side events after the settle step.

  ## Examples

      conn
      |> trigger_after_settle("settled")
      |> html("<div>Content</div>")
  """
  @spec trigger_after_settle(Plug.Conn.t(), String.t() | list(String.t())) :: Plug.Conn.t()
  def trigger_after_settle(conn, event) when is_binary(event) do
    Plug.Conn.put_resp_header(conn, "hx-trigger-after-settle", event)
  end

  def trigger_after_settle(conn, events) when is_list(events) do
    Plug.Conn.put_resp_header(conn, "hx-trigger-after-settle", Enum.join(events, ", "))
  end

  @spec trigger_after_settle(Plug.Conn.t(), String.t(), map()) :: Plug.Conn.t()
  def trigger_after_settle(conn, event, detail) when is_binary(event) and is_map(detail) do
    trigger_json = Jason.encode!(%{event => detail})
    Plug.Conn.put_resp_header(conn, "hx-trigger-after-settle", trigger_json)
  end
end
