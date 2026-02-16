# FrancisHtmx
[![Hex version badge](https://img.shields.io/hexpm/v/francis_htmx.svg)](https://hex.pm/packages/francis_htmx)
[![License badge](https://img.shields.io/hexpm/l/repo_example.svg)](https://github.com/filipecabaco/francis_htmx/blob/master/LICENSE.md)
[![Elixir CI](https://github.com/filipecabaco/francis_htmx/actions/workflows/elixir.yaml/badge.svg)](https://github.com/filipecabaco/francis_htmx/actions/workflows/elixir.yaml)

A simple, powerful DSL for building HTMX-powered web applications with Francis.

FrancisHtmx provides a clean, Elixir-friendly way to work with HTMX, including support for extensions, request/response headers, reusable components, and attribute helpers.

## Features

- **Simple DSL**: Clean macro-based API for defining HTMX applications
- **MPA Support**: Built-in helpers for Multi-Page Applications with progressive enhancement
- **Extensions Support**: Easy integration with HTMX extensions (SSE, WebSockets, etc.)
- **Headers Management**: Helper functions for HTMX request and response headers
- **Components**: Build reusable, composable HTMX components
- **Attribute Helpers**: Functional API for generating HTMX attributes
- **~H Sigil**: HEEx templating with full Phoenix Component support

## Installation

Add `francis_htmx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:francis_htmx, "~> 0.2.3"}
  ]
end
```

## Quick Start

```elixir
defmodule Example do
  use Francis
  use FrancisHtmx, version: "2", title: "HTMX Example"

  htmx(fn _conn ->
    assigns = %{}

    ~H"""
    <div hx-get="/colors" hx-trigger="every 1s">
      <p id="color-demo">Color Swap Demo</p>
    </div>
    """
  end)

  get("/colors", fn _ ->
    new_color = 3 |> :crypto.strong_rand_bytes() |> Base.encode16() |> then(&"##{&1}")
    assigns = %{new_color: new_color}

    ~H"""
    <p id="color-demo" style={"color:#{@new_color}"}>
      Color Swap Demo
    </p>
    """
  end)
end
```

## Extensions Support

HTMX extensions add powerful features to your application. FrancisHtmx makes it easy to load and use them.

```elixir
defmodule MyApp do
  use Francis
  use FrancisHtmx
  import FrancisHtmx.Extensions

  htmx(
    fn _conn ->
      assigns = %{}

      ~H"""
      <div hx-ext="sse">
        <div hx-sse="connect:/events">
          <div hx-sse="swap:message">
            Waiting for messages...
          </div>
        </div>
      </div>
      """
    end,
    extensions: [:sse]
  )
end
```

### Available Extensions

Core extensions (officially supported):
- `:sse` - Server-Sent Events
- `:ws` - WebSockets
- `:response_targets` - Different targets based on response codes
- `:preload` - Preload content into browser cache
- `:idiomorph` - Morphing swap strategy
- `:head_support` - Merge head tag information

Use custom extensions by passing a URL:
```elixir
htmx(content, extensions: ["https://example.com/my-extension.js"])
```

## Headers Management

Work with HTMX request and response headers using the `FrancisHtmx.Headers` module.

### Request Headers

```elixir
import FrancisHtmx.Headers

get("/data", fn conn ->
  if htmx_request?(conn) do
    target = get_target(conn)
    trigger = get_trigger(conn)

    html(conn, "<div>Partial content for #{target}</div>")
  else
    html(conn, "<html>Full page</html>")
  end
end)
```

Available request header functions:
- `htmx_request?/1` - Check if request is from HTMX
- `get_trigger/1` - Get ID of triggering element
- `get_trigger_name/1` - Get name of triggering element
- `get_target/1` - Get ID of target element
- `get_current_url/1` - Get current browser URL
- `get_prompt/1` - Get user's response to a prompt
- `boosted?/1` - Check if request was boosted
- `history_restore_request?/1` - Check if history restore

### Response Headers

```elixir
import FrancisHtmx.Headers

post("/items", fn conn ->
  # Add item logic...

  conn
  |> trigger("itemAdded", %{id: 123})
  |> push_url("/items/123")
  |> html("<div>Item added</div>")
end)
```

Available response header functions:
- `trigger/2` - Trigger client-side events
- `trigger_after_swap/2` - Trigger after swap
- `trigger_after_settle/2` - Trigger after settle
- `push_url/2` - Push URL to history
- `replace_url/2` - Replace current URL
- `hx_redirect/2` - Full page redirect
- `refresh/1` - Trigger page refresh
- `retarget/2` - Change swap target
- `reswap/2` - Change swap strategy
- `reselect/2` - Select part of response to swap
- `location/2` - Client-side redirect without reload

## Components

Build reusable HTMX components using `FrancisHtmx.Components` and the `~H` sigil.

```elixir
defmodule MyApp.Components do
  use FrancisHtmx
  import FrancisHtmx.Components

  def user_card(user) do
    assigns = %{user: user}

    ~H"""
    <div class="card" id={"user-#{@user.id}"}>
      <h3>{@user.name}</h3>
      <button hx-delete={"/users/#{@user.id}"}
              hx-target={"#user-#{@user.id}"}
              hx-swap="outerHTML">
        Delete
      </button>
    </div>
    """
  end
end
```

### Component Helpers

- `wrapper/3` - Create wrapper divs with attributes
- `fragment/2` - Create swappable fragments
- `htmx_or_full/2` - Conditionally render based on request type

## Attribute Helpers

Generate HTMX attributes functionally using `FrancisHtmx.Attributes`.

```elixir
import FrancisHtmx.Attributes

attrs = combine([
  hx_post("/submit"),
  hx_target("#results"),
  hx_swap("innerHTML"),
  hx_indicator("#spinner")
])
```

### Available Attribute Functions

**HTTP Methods**: `hx_get`, `hx_post`, `hx_put`, `hx_patch`, `hx_delete`

**Targeting**: `hx_target`, `hx_swap`, `hx_select`, `hx_swap_oob`

**Triggers**: `hx_trigger`

**Data**: `hx_vals`, `hx_include`, `hx_headers`

**URL Management**: `hx_push_url`, `hx_replace_url`

**UI Feedback**: `hx_indicator`, `hx_disabled_elt`

**Validation**: `hx_confirm`, `hx_prompt`, `hx_validate`

**Advanced**: `hx_sync`, `hx_boost`, `hx_disable`

**Chaining**: `combine/1` - Combine multiple attributes

## Building Multi-Page Applications (MPA) with HTMX

FrancisHtmx provides content negotiation for Multi-Page Applications: direct URL access returns a full page, HTMX requests return only the content partial, and browser history restore works correctly.

You write your own HTML layout — the library only decides *when* to wrap content in it.

### Define Your Layout

A layout function receives `%{content: content, title: title}` and returns the full HTML page:

```elixir
defmodule MyApp.Router do
  use Francis
  use FrancisHtmx

  def my_layout(assigns) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <title>#{assigns.title}</title>
        <script src="https://unpkg.com/htmx.org@2"></script>
      </head>
      <body hx-boost="true">
        <nav>
          <a href="/" hx-get="/" hx-target="#main" hx-swap="innerHTML" hx-push-url="true">Home</a>
          <a href="/about" hx-get="/about" hx-target="#main" hx-swap="innerHTML" hx-push-url="true">About</a>
        </nav>
        <div id="main">#{assigns.content}</div>
      </body>
    </html>
    """
  end

  @page_opts [title: "My App", layout: &MyApp.Router.my_layout/1]

  route "/", fn ->
    assigns = %{}

    ~H"""
    <h1>Welcome</h1>
    """
  end, @page_opts

  route "/about", fn ->
    assigns = %{}

    ~H"""
    <h1>About Us</h1>
    """
  end, @page_opts
end
```

### Using `render_page/3` Directly

For routes that need access to `conn` (e.g. query params):

```elixir
get("/search", fn conn ->
  query = conn.params["q"] || ""
  assigns = %{query: query}

  render_page(conn, fn ->
    ~H"""
    <h1>Results for {@query}</h1>
    """
  end, @page_opts)
end)
```

### How It Works

- **Direct access** (`GET /about`) — `render_page` calls `content_fn`, passes the result to your layout, returns full HTML
- **HTMX request** (clicking a nav link) — returns only the content partial, swapped into the target element
- **History restore** (browser back after cache expires) — returns full page with content, so the page is never blank

### Configuration Options

- `:layout` - Function receiving `%{content: String.t(), title: String.t()}`, returns full HTML page. When omitted, a minimal default layout is used.
- `:title` - Page title passed to the layout (default: "FrancisHTMX App")
- `:target` - Content div ID for the default layout (default: "main-content")

## Tailwind CSS

FrancisHtmx works with [phoenixframework/tailwind](https://github.com/phoenixframework/tailwind) — the same standalone Tailwind CLI used by Phoenix, with no Phoenix dependency required.

### Setup

1. Add the dependency to `mix.exs`:

```elixir
{:tailwind, "~> 0.3", runtime: Mix.env() == :dev}
```

2. Configure Tailwind v4 in `config/config.exs`:

```elixir
config :tailwind,
  version: "4.1.4",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]
```

3. Create `assets/css/app.css`:

```css
@import "tailwindcss";
```

4. Install the Tailwind binary and build:

```bash
mix tailwind.install
mix tailwind default
```

5. Add the stylesheet to your layout:

```elixir
def my_layout(assigns) do
  """
  <!DOCTYPE html>
  <html>
    <head>
      <link rel="stylesheet" href="/assets/css/app.css" />
      <script src="https://unpkg.com/htmx.org@2"></script>
      <title>#{assigns.title}</title>
    </head>
    <body>
      <div id="main">#{assigns.content}</div>
    </body>
  </html>
  """
end
```

Francis serves files from `priv/static` via `Plug.Static` automatically, so the compiled CSS is available at `/assets/css/app.css`.

### Development Watcher

For automatic recompilation during development, add a watcher to your supervision tree:

```elixir
children = [
  {Tailwind, name: :default, args: ~w(--watch)}
]
```

See the [example app](example/) for a complete working setup with Tailwind CSS and Heroicons.

## API Documentation

Full API documentation is available on [HexDocs](https://hexdocs.pm/francis_htmx).

## Resources

- [HTMX Documentation](https://htmx.org/docs/)
- [HTMX Extensions](https://extensions.htmx.org)
- [Francis Framework](https://github.com/filipecabaco/francis)

## License

MIT License - see [LICENSE](LICENSE) for details.
