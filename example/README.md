# Taskflow — Francis HTMX Example

A minimal dark Task Manager built with [Francis](https://github.com/filipecabaco/francis) and [Francis HTMX](https://github.com/filipecabaco/francis_htmx).

## Features

- **Full CRUD** — Add, edit, toggle, and delete tasks
- **Inline edit** — Click a task title to edit it
- **Priority** — Star important tasks (high priority)
- **Clear completed** — Remove all done tasks in one action
- **Search** — Live search (300ms debounce)
- **Filter** — All, To do, Done
- **Dark minimalist UI** — Easy on the eyes
- **Relative timestamps** — "2h ago", "3d ago"
- **Heroicons** — Check icons via [ex_heroicons](https://hexdocs.pm/ex_heroicons/)

## Run It

```bash
cd example
mix deps.get
mix run --no-halt
```

Open [http://localhost:4000](http://localhost:4000)

**Dev mode**: `config/dev.exs` sets `config :francis, dev: true`, enabling Francis's file watcher. When you run `mix run --no-halt` (default MIX_ENV=dev), the app auto-recompiles on `.ex`/`.exs` changes.

## Francis HTMX Features Demonstrated

| Feature | Usage |
|---------|-------|
| `route` macro | MPA pages |
| `render_page` | Full vs partial based on `HX-Request` |
| `htmx_request?/1` | Conditional list/filter handling |
| `push_url/2` | URL updates after form submit |
| `trigger/2` | Client events |
| `hx-confirm` | Delete + clear-completed confirmation |
| `hx-patch` / `hx-put` / `hx-delete` | Inline toggle, edit, delete, priority |
| `hx-trigger` | `blur`, `click once`, `input delay` |
| `hx-boost` | Automatic AJAX navigation via body attribute |

## Project Structure

```
example/
├── lib/
│   ├── example.ex         # Router, routes, rendering
│   └── example/
│       └── task_store.ex   # In-memory CRUD via Agent
├── mix.exs
└── README.md
```
