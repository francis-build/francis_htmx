# FrancisHtmx
[![Hex version badge](https://img.shields.io/hexpm/v/francis_htmx.svg)](https://hex.pm/packages/francis_htmx)
[![License badge](https://img.shields.io/hexpm/l/repo_example.svg)](https://github.com/filipecabaco/francis_htmx/blob/master/LICENSE.md)
[![Elixir CI](https://github.com/filipecabaco/francis_htmx/actions/workflows/elixir.yaml/badge.svg)](https://github.com/filipecabaco/francis_htmx/actions/workflows/elixir.yaml)

Simple helper function to add a new htmx macro that can be used by Francis to provide a simple HTMX server.

It also uses ~E that is implemented similarly to ~H sigil from Phoenix Liveview to load information into templates.

## Installation
If available in Hex, the package can be installed by adding francis to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    {:francis_htmx, "~> 0.1.0"}
  ]
end
```
## Usage
```elixir
defmodule Example do
  use Francis

  use FrancisHtmx,
    version: "2",
    title: "Testing HTMX",
    head: ~E"""
      <script src="https://cdn.tailwindcss.com"></script>
      <link href="/app.css" rel="stylesheet">
    """

  htmx(fn _conn ->
    ~E"""
    <style>
      .smooth {   transition: all 1s ease-in; font-size: 8rem; }
    </style>
    <div hx-get="/colors" hx-trigger="every 1s">
      <p id="color-demo" class="smooth">Color Swap Demo</p>
    </div>
    """
  end)

  get("/colors", fn _ ->
    new_color = 3 |> :crypto.strong_rand_bytes() |> Base.encode16() |> then(&"##{&1}")
    assigns = %{new_color: new_color}

    ~E"""
    <p id="color-demo" class="smooth" style="<%= "color:#{@new_color}"%>">
    Color Swap Demo
    </p>
    """
  end)
end

```