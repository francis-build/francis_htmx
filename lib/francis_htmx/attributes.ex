defmodule FrancisHtmx.Attributes do
  @moduledoc """
  Helper module for building HTMX attributes in a clean, functional way.

  This module provides functions to generate HTMX attributes as strings
  that can be easily interpolated into HTML templates.

  ## Usage

      use FrancisHtmx
      import FrancisHtmx.Attributes

      attrs = combine([
        hx_get("/data"),
        hx_trigger("click"),
        hx_target("#results")
      ])

      htmx(fn _conn ->
        ~H\"\"\"
        <div \#{attrs}>
          Click me
        </div>
        <div id="results"></div>
        \"\"\"
      end)
  """

  @doc """
  Issues a GET request to the given URL.

  ## Examples

      hx_get("/api/data")
      #=> ~s(hx-get="/api/data")
  """
  @spec hx_get(String.t()) :: String.t()
  def hx_get(url), do: ~s(hx-get="#{url}")

  @doc """
  Issues a POST request to the given URL.

  ## Examples

      hx_post("/api/submit")
      #=> ~s(hx-post="/api/submit")
  """
  @spec hx_post(String.t()) :: String.t()
  def hx_post(url), do: ~s(hx-post="#{url}")

  @doc """
  Issues a PUT request to the given URL.

  ## Examples

      hx_put("/api/update/1")
      #=> ~s(hx-put="/api/update/1")
  """
  @spec hx_put(String.t()) :: String.t()
  def hx_put(url), do: ~s(hx-put="#{url}")

  @doc """
  Issues a PATCH request to the given URL.

  ## Examples

      hx_patch("/api/update/1")
      #=> ~s(hx-patch="/api/update/1")
  """
  @spec hx_patch(String.t()) :: String.t()
  def hx_patch(url), do: ~s(hx-patch="#{url}")

  @doc """
  Issues a DELETE request to the given URL.

  ## Examples

      hx_delete("/api/delete/1")
      #=> ~s(hx-delete="/api/delete/1")
  """
  @spec hx_delete(String.t()) :: String.t()
  def hx_delete(url), do: ~s(hx-delete="#{url}")

  @doc """
  Specifies the target element for the swap.

  ## Examples

      hx_target("#results")
      #=> ~s(hx-target="#results")

      hx_target("closest .container")
      #=> ~s(hx-target="closest .container")
  """
  @spec hx_target(String.t()) :: String.t()
  def hx_target(selector), do: ~s(hx-target="#{selector}")

  @doc """
  Specifies how the response will be swapped.

  ## Options

  - `innerHTML` - Replace inner HTML (default)
  - `outerHTML` - Replace entire element
  - `beforebegin` - Insert before the target
  - `afterbegin` - Insert before first child
  - `beforeend` - Insert after last child
  - `afterend` - Insert after the target
  - `delete` - Delete the target
  - `none` - No swap

  ## Examples

      hx_swap("outerHTML")
      #=> ~s(hx-swap="outerHTML")

      hx_swap("innerHTML swap:1s settle:0.5s")
      #=> ~s(hx-swap="innerHTML swap:1s settle:0.5s")
  """
  @spec hx_swap(String.t()) :: String.t()
  def hx_swap(strategy), do: ~s(hx-swap="#{strategy}")

  @doc """
  Specifies what triggers the request.

  ## Examples

      hx_trigger("click")
      #=> ~s(hx-trigger="click")

      hx_trigger("every 2s")
      #=> ~s(hx-trigger="every 2s")

      hx_trigger("click, keyup delay:500ms")
      #=> ~s(hx-trigger="click, keyup delay:500ms")
  """
  @spec hx_trigger(String.t()) :: String.t()
  def hx_trigger(event), do: ~s(hx-trigger="#{event}")

  @doc """
  Adds values to submit with the request.

  ## Examples

      hx_vals(~s({"key": "value"}))
      #=> ~s(hx-vals="{\\"key\\": \\"value\\"}")

      hx_vals("js:{computed: getComputedValue()}")
      #=> ~s(hx-vals="js:{computed: getComputedValue()}")
  """
  @spec hx_vals(String.t()) :: String.t()
  def hx_vals(values), do: ~s(hx-vals="#{escape_quotes(values)}")

  @doc """
  Includes additional elements in the request.

  ## Examples

      hx_include("#form-1, #form-2")
      #=> ~s(hx-include="#form-1, #form-2")
  """
  @spec hx_include(String.t()) :: String.t()
  def hx_include(selector), do: ~s(hx-include="#{selector}")

  @doc """
  Shows a confirmation dialog before issuing the request.

  ## Examples

      hx_confirm("Are you sure?")
      #=> ~s(hx-confirm="Are you sure?")
  """
  @spec hx_confirm(String.t()) :: String.t()
  def hx_confirm(message), do: ~s(hx-confirm="#{escape_quotes(message)}")

  @doc """
  Shows a prompt dialog before issuing the request.

  ## Examples

      hx_prompt("Enter your name")
      #=> ~s(hx-prompt="Enter your name")
  """
  @spec hx_prompt(String.t()) :: String.t()
  def hx_prompt(message), do: ~s(hx-prompt="#{escape_quotes(message)}")

  @doc """
  Pushes a URL into the browser location bar.

  ## Examples

      hx_push_url("true")
      #=> ~s(hx-push-url="true")

      hx_push_url("/new-url")
      #=> ~s(hx-push-url="/new-url")
  """
  @spec hx_push_url(String.t() | boolean()) :: String.t()
  def hx_push_url(value), do: ~s(hx-push-url="#{value}")

  @doc """
  Replaces the current URL in the browser location bar.

  ## Examples

      hx_replace_url("true")
      #=> ~s(hx-replace-url="true")

      hx_replace_url("/updated-url")
      #=> ~s(hx-replace-url="/updated-url")
  """
  @spec hx_replace_url(String.t() | boolean()) :: String.t()
  def hx_replace_url(value), do: ~s(hx-replace-url="#{value}")

  @doc """
  Selects a portion of the response to swap in.

  ## Examples

      hx_select("#content")
      #=> ~s(hx-select="#content")
  """
  @spec hx_select(String.t()) :: String.t()
  def hx_select(selector), do: ~s(hx-select="#{selector}")

  @doc """
  Performs out-of-band swaps.

  ## Examples

      hx_swap_oob("true")
      #=> ~s(hx-swap-oob="true")

      hx_swap_oob("innerHTML:#notifications")
      #=> ~s(hx-swap-oob="innerHTML:#notifications")
  """
  @spec hx_swap_oob(String.t() | boolean()) :: String.t()
  def hx_swap_oob(value), do: ~s(hx-swap-oob="#{value}")

  @doc """
  Specifies the element to show during the request.

  ## Examples

      hx_indicator("#spinner")
      #=> ~s(hx-indicator="#spinner")
  """
  @spec hx_indicator(String.t()) :: String.t()
  def hx_indicator(selector), do: ~s(hx-indicator="#{selector}")

  @doc """
  Adds headers to the request.

  ## Examples

      hx_headers(~s({"X-Custom": "value"}))
      #=> ~s(hx-headers="{\\"X-Custom\\": \\"value\\"}")
  """
  @spec hx_headers(String.t()) :: String.t()
  def hx_headers(headers), do: ~s(hx-headers="#{escape_quotes(headers)}")

  @doc """
  Enables or disables an element during the request.

  ## Examples

      hx_disabled_elt("this")
      #=> ~s(hx-disabled-elt="this")

      hx_disabled_elt("#submit-btn")
      #=> ~s(hx-disabled-elt="#submit-btn")
  """
  @spec hx_disabled_elt(String.t()) :: String.t()
  def hx_disabled_elt(selector), do: ~s(hx-disabled-elt="#{selector}")

  @doc """
  Synchronizes requests.

  ## Examples

      hx_sync("this:drop")
      #=> ~s(hx-sync="this:drop")

      hx_sync("closest form:abort")
      #=> ~s(hx-sync="closest form:abort")
  """
  @spec hx_sync(String.t()) :: String.t()
  def hx_sync(strategy), do: ~s(hx-sync="#{strategy}")

  @doc """
  Boosts normal anchors and forms.

  ## Examples

      hx_boost("true")
      #=> ~s(hx-boost="true")
  """
  @spec hx_boost(String.t() | boolean()) :: String.t()
  def hx_boost(value), do: ~s(hx-boost="#{value}")

  @doc """
  Validates before submitting.

  ## Examples

      hx_validate("true")
      #=> ~s(hx-validate="true")
  """
  @spec hx_validate(String.t() | boolean()) :: String.t()
  def hx_validate(value), do: ~s(hx-validate="#{value}")

  @doc """
  Disables htmx processing for an element.

  ## Examples

      hx_disable("true")
      #=> ~s(hx-disable="true")
  """
  @spec hx_disable(String.t() | boolean()) :: String.t()
  def hx_disable(value), do: ~s(hx-disable="#{value}")

  @doc """
  Chains multiple HTMX attributes together.

  ## Examples

      combine([
        hx_get("/data"),
        hx_trigger("click"),
        hx_target("#results")
      ])
      #=> ~s(hx-get="/data" hx-trigger="click" hx-target="#results")
  """
  @spec combine(list(String.t())) :: String.t()
  def combine(attrs) when is_list(attrs) do
    Enum.join(attrs, " ")
  end

  defp escape_quotes(str) do
    String.replace(str, "\"", "\\\"")
  end
end
