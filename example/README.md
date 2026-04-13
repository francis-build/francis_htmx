# FrancisHtmx Example

A demo application showing FrancisHtmx in action with a color-swapping widget.

## Running

```bash
cd example
mix deps.get
mix run --no-halt
```

Then open http://localhost:4000 in your browser.

## What it demonstrates

- `use FrancisHtmx` with a custom title
- The `htmx` macro generating a full HTML page with htmx inlined
- `hx-get` and `hx-trigger` for polling an endpoint every second
- The `~E` sigil with `@assigns` for dynamic HTML fragments
- CSS transitions driven by htmx DOM swaps
