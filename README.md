# FrancisHtmx
[![Hex version badge](https://img.shields.io/hexpm/v/francis_htmx.svg)](https://hex.pm/packages/francis_htmx)
[![License badge](https://img.shields.io/hexpm/l/repo_example.svg)](https://github.com/filipecabaco/francis_htmx/blob/master/LICENSE.md)
[![Elixir CI](https://github.com/filipecabaco/francis_htmx/actions/workflows/elixir.yaml/badge.svg)](https://github.com/filipecabaco/francis_htmx/actions/workflows/elixir.yaml)

HTMX integration for the [Francis](https://hex.pm/packages/francis) web framework.

Provides an `htmx` macro that generates a fully structured HTML page with htmx.js
bundled inline — no CDN dependency required. Also includes the `~E` sigil for
EEx templating with assigns, similar to Phoenix LiveView's `~H`.

## Features

- **Bundled htmx.js** — htmx is inlined at compile time, so pages work without network access to CDNs
- **Proper HTML5 output** — generates `lang`, `charset`, `viewport` meta, and `cache-control` headers aligned with Francis v0.3
- **XSS-safe titles** — page titles are escaped via `Francis.HTML.escape/1`
- **`~E` sigil** — EEx templates with `@assigns` support and automatic HTML escaping via Phoenix.HTML
- **`mix francis_htmx.update`** — easily download a specific htmx version from GitHub

## Installation

Add `francis_htmx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:francis_htmx, "~> 0.3.0"}
  ]
end
```

## Usage

```elixir
defmodule MyApp do
  use Francis
  use FrancisHtmx, title: "My App"

  htmx(fn _conn ->
    ~E"""
    <h1>Hello from HTMX!</h1>
    <div hx-get="/greeting" hx-trigger="click">
      Click me
    </div>
    """
  end)

  get("/greeting", fn _ ->
    assigns = %{name: "World"}

    ~E"""
    <p>Hello, <%= @name %>!</p>
    """
  end)
end
```

### Options

`use FrancisHtmx` accepts the following options:

| Option   | Description                                               | Default |
|----------|-----------------------------------------------------------|---------|
| `:title` | HTML page title (escaped automatically)                   | `""`    |
| `:head`  | Additional HTML to inject in `<head>` (scripts, styles)   | `""`    |

These can also be overridden per-page using the two-argument form:

```elixir
htmx(
  fn _conn ->
    ~E"""<h1>Custom page</h1>"""
  end,
  title: "Custom Title",
  head: ~E"""<link href="/custom.css" rel="stylesheet">"""
)
```

### The `~E` sigil

Renders EEx templates with `@assigns` support, similar to Phoenix LiveView's `~H`:

```elixir
get("/colors", fn _ ->
  new_color = 3 |> :crypto.strong_rand_bytes() |> Base.encode16() |> then(&"##{&1}")
  assigns = %{color: new_color}

  ~E"""
  <p style="color: <%= @color %>"><%= @color %></p>
  """
end)
```

If no `assigns` variable exists in the current scope, an empty map is used automatically.

## Updating htmx

The bundled htmx.js can be updated to any version via the included Mix task:

```bash
mix francis_htmx.update          # downloads the latest release
mix francis_htmx.update 2.0.4    # downloads a specific version
```

After updating, recompile your project to pick up the new version:

```bash
mix compile --force
```

## Migrating from v0.2

- The `:version` option is **deprecated** — htmx is now bundled and inlined instead of loaded from a CDN. Use `mix francis_htmx.update` to manage versions.
- Requires `francis ~> 0.3.0` for `Francis.HTML.escape/1` and improved HTML response headers.
- Generated HTML now includes `lang="en"`, `<meta charset="utf-8">`, and `<meta name="viewport">`.
