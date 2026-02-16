defmodule Example do
  use Francis
  use FrancisHtmx, version: "2", title: "Taskflow"
  import FrancisHtmx.Page
  import FrancisHtmx.Headers

  @impl Application
  def start(_type, _args) do
    dev = Application.get_env(:francis, :dev, false)

    children =
      [
        {Example.TaskStore, []}
        | if(Mix.env() == :test, do: [], else: [{Bandit, plug: __MODULE__}])
      ] ++ if(dev, do: [{Francis.Watcher, []}], else: [])

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def taskflow_layout(assigns) do
    """
    <!DOCTYPE html>
    <html class="dark">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <script src="https://unpkg.com/htmx.org@2"></script>
        <title>#{assigns.title}</title>
        <link rel="stylesheet" href="/assets/css/app.css" />
      </head>
      <body class="bg-neutral-950 text-neutral-200 font-sans text-[15px] antialiased leading-relaxed" hx-boost="true">
        <nav class="max-w-xl mx-auto px-6 pt-6 flex gap-2 border-b border-neutral-800">
          <a href="/" hx-get="/" hx-target="#main-content" hx-swap="innerHTML" hx-push-url="true"
             class="text-neutral-500 no-underline py-3 text-sm border-b-2 border-transparent transition-colors hover:text-neutral-400">Tasks</a>
          <a href="/about" hx-get="/about" hx-target="#main-content" hx-swap="innerHTML" hx-push-url="true"
             class="text-neutral-500 no-underline py-3 text-sm border-b-2 border-transparent transition-colors hover:text-neutral-400">About</a>
        </nav>
        <div id="main-content" class="max-w-xl mx-auto px-6 py-8">
          #{assigns.content}
        </div>
      </body>
    </html>
    """
  end

  @page_opts [title: "Taskflow", layout: &Example.taskflow_layout/1]

  # --- Routes ---

  route "/", fn ->
    tasks = Example.TaskStore.list_tasks()
    stats = Example.TaskStore.count_by_status()
    Example.render_task_list(tasks, "", "all", stats)
  end, @page_opts

  get "/tasks", fn conn ->
    {search, status_filter} = extract_filters(conn.params)
    tasks = Example.TaskStore.list_tasks(q: nillify(search), status: nillify_status(status_filter))
    stats = Example.TaskStore.count_by_status()

    render_page(conn, fn ->
      Example.render_task_list(tasks, search, status_filter, stats)
    end, @page_opts)
  end

  route "/tasks/new", fn ->
    assigns = %{}

    ~H"""
    <div class="mb-6">
      <h1 class="text-xl font-medium text-neutral-200 tracking-tight">New task</h1>
    </div>
    <form hx-post="/tasks" hx-target="#main-content" hx-swap="innerHTML" hx-push-url="true">
      <div class="mb-5">
        <label for="title" class="block mb-2 text-sm text-neutral-500">What needs to be done?</label>
        <input type="text" id="title" name="title" placeholder="Add a task..." required autofocus
               class="w-full py-3.5 px-4 bg-neutral-900 border border-neutral-800 rounded-md text-neutral-200 text-[15px] placeholder-neutral-600 focus:outline-none focus:border-neutral-600" />
      </div>
      <div class="flex gap-3 mt-6">
        <button type="submit" class="bg-transparent text-neutral-200 border border-neutral-600 px-4 py-2 rounded-md cursor-pointer text-sm transition-all hover:border-neutral-500">Add</button>
        <a href="/" hx-get="/" hx-target="#main-content" hx-swap="innerHTML" hx-push-url="true"
           class="bg-transparent text-neutral-500 border border-neutral-800 px-4 py-2 rounded-md cursor-pointer text-sm transition-all hover:text-neutral-400 hover:border-neutral-600">Cancel</a>
      </div>
    </form>
    """
  end, @page_opts

  route "/about", fn ->
    assigns = %{}

    ~H"""
    <div class="max-w-xl mx-auto">
      <h1 class="text-xl font-medium mb-4">About Taskflow</h1>
      <p class="text-neutral-500 mb-3 text-[15px]">A minimal task manager built with <a href="https://github.com/filipecabaco/francis" class="text-blue-400 no-underline hover:underline">Francis</a>
         and <a href="https://github.com/filipecabaco/francis_htmx" class="text-blue-400 no-underline hover:underline">FrancisHtmx</a>.</p>
      <p class="text-neutral-500 mb-3 text-[15px]">This example demonstrates multi-page navigation with <code class="bg-neutral-900 px-1.5 rounded text-sm">hx-boost</code>,
         partial page updates via HTMX, and proper browser history support.</p>
      <p class="text-neutral-500 mb-3 text-[15px]">Try navigating between <strong>Tasks</strong> and <strong>About</strong> using the nav links,
         then use your browser's back/forward buttons to verify history works correctly.</p>
    </div>
    """
  end, @page_opts

  post "/tasks", fn conn ->
    Example.TaskStore.add_task(conn.params)
    {search, status_filter} = extract_filters(conn.params)
    tasks = Example.TaskStore.list_tasks(q: nillify(search), status: nillify_status(status_filter))
    stats = Example.TaskStore.count_by_status()

    conn
    |> push_url("/")
    |> trigger("taskAdded")
    |> put_resp_content_type("text/html")
    |> send_resp(200, Example.render_task_list(tasks, search, status_filter, stats))
  end

  put "/tasks/:id", fn conn ->
    id = conn.params["id"]
    Example.TaskStore.update_task(id, conn.params)
    task = Example.TaskStore.get_task(id)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Example.render_task_row(task))
  end

  get "/tasks/:id/edit", fn conn ->
    task = Example.TaskStore.get_task(conn.params["id"])

    if task do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, Example.render_task_row(task, true))
    else
      conn |> send_resp(404, "")
    end
  end

  patch "/tasks/:id/toggle", fn conn ->
    id = conn.params["id"]
    Example.TaskStore.toggle_task(id)
    task = Example.TaskStore.get_task(id)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Example.render_task_row(task))
  end

  patch "/tasks/:id/priority", fn conn ->
    id = conn.params["id"]
    Example.TaskStore.toggle_priority(id)
    task = Example.TaskStore.get_task(id)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Example.render_task_row(task))
  end

  post "/tasks/mark-all-done", fn conn ->
    Example.TaskStore.mark_all_done()
    {search, status_filter} = extract_filters(conn.params)
    tasks = Example.TaskStore.list_tasks()
    stats = Example.TaskStore.count_by_status()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Example.render_task_list(tasks, search, status_filter, stats))
  end

  post "/tasks/mark-all-todo", fn conn ->
    Example.TaskStore.mark_all_todo()
    {search, status_filter} = extract_filters(conn.params)
    tasks = Example.TaskStore.list_tasks()
    stats = Example.TaskStore.count_by_status()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Example.render_task_list(tasks, search, status_filter, stats))
  end

  post "/tasks/clear-completed", fn conn ->
    Example.TaskStore.clear_completed()
    {search, status_filter} = extract_filters(conn.params)
    tasks = Example.TaskStore.list_tasks()
    stats = Example.TaskStore.count_by_status()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Example.render_task_list(tasks, search, status_filter, stats))
  end

  delete "/tasks/:id", fn conn ->
    Example.TaskStore.delete_task(conn.params["id"])
    tasks = Example.TaskStore.list_tasks()
    stats = Example.TaskStore.count_by_status()
    search = Map.get(conn.params, "q", "")

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Example.render_task_list(tasks, search, "all", stats))
  end

  # --- Rendering ---

  def render_task_list(tasks, search, status_filter, stats) do
    task_rows = tasks |> Enum.map(&Example.render_task_row/1) |> Enum.join("\n")

    assigns = %{
      tasks: tasks,
      task_rows: Phoenix.HTML.raw(task_rows),
      search: search,
      status_filter: status_filter,
      stats: stats
    }

    FrancisHtmx.rendered_to_string(~H"""
    <div class="mb-6">
      <h1 class="text-xl font-medium text-neutral-200 tracking-tight">Tasks</h1>
      <div class="flex gap-6 mt-1.5 text-[13px] text-neutral-600">
        <span>{@stats.todo} to do</span>
        <span>{@stats.done} done</span>
      </div>
    </div>

    <div class="flex gap-4 items-center mb-6 flex-wrap">
      <form id="search-form" hx-get="/tasks" hx-target="#main-content" hx-swap="innerHTML" hx-push-url="true"
            hx-trigger="input from:#search-input delay:300ms">
        <input type="hidden" name="status" value={@status_filter} />
        <input type="search" id="search-input" name="q" value={@search} placeholder="Search..."
               class="py-2 px-3 bg-neutral-900 border border-neutral-800 rounded-md text-neutral-200 min-w-[200px] text-[15px] placeholder-neutral-600 transition-colors focus:outline-none focus:border-neutral-600" />
      </form>
      <div class="flex gap-1">
        <a href="/tasks?status=all" class={"no-underline py-1.5 px-3 rounded-md text-[13px] transition-colors #{if @status_filter == "all", do: "text-neutral-200 bg-neutral-800", else: "text-neutral-600 hover:text-neutral-400"}"}
           hx-get="/tasks?status=all" hx-target="#main-content" hx-swap="innerHTML" hx-push-url="true">All</a>
        <a href="/tasks?status=todo" class={"no-underline py-1.5 px-3 rounded-md text-[13px] transition-colors #{if @status_filter == "todo", do: "text-neutral-200 bg-neutral-800", else: "text-neutral-600 hover:text-neutral-400"}"}
           hx-get="/tasks?status=todo" hx-target="#main-content" hx-swap="innerHTML" hx-push-url="true">To do</a>
        <a href="/tasks?status=done" class={"no-underline py-1.5 px-3 rounded-md text-[13px] transition-colors #{if @status_filter == "done", do: "text-neutral-200 bg-neutral-800", else: "text-neutral-600 hover:text-neutral-400"}"}
           hx-get="/tasks?status=done" hx-target="#main-content" hx-swap="innerHTML" hx-push-url="true">Done</a>
      </div>
      <div class="flex gap-2 ml-auto">
        <form :if={@stats.todo > 0 and @tasks != []} hx-post="/tasks/mark-all-done" hx-target="#main-content" hx-swap="innerHTML">
          <input type="hidden" name="q" value={@search} />
          <input type="hidden" name="status" value={@status_filter} />
          <button type="submit" class="bg-transparent text-neutral-500 border border-neutral-800 py-1.5 px-3 rounded-md cursor-pointer text-[13px] transition-all hover:text-neutral-400 hover:border-neutral-600">Done all</button>
        </form>
        <form :if={@stats.done > 0 and @tasks != []} hx-post="/tasks/mark-all-todo" hx-target="#main-content" hx-swap="innerHTML">
          <input type="hidden" name="q" value={@search} />
          <input type="hidden" name="status" value={@status_filter} />
          <button type="submit" class="bg-transparent text-neutral-500 border border-neutral-800 py-1.5 px-3 rounded-md cursor-pointer text-[13px] transition-all hover:text-neutral-400 hover:border-neutral-600">To do all</button>
        </form>
        <form :if={@stats.done > 0} class="ml-auto" hx-post="/tasks/clear-completed" hx-target="#main-content" hx-swap="innerHTML"
              hx-confirm={"Clear #{@stats.done} completed task#{if @stats.done == 1, do: "", else: "s"}?"}>
          <input type="hidden" name="q" value={@search} />
          <input type="hidden" name="status" value={@status_filter} />
          <button type="submit" class="bg-transparent text-neutral-500 border border-neutral-800 py-1.5 px-3 rounded-md cursor-pointer text-[13px] transition-all hover:text-neutral-400 hover:border-neutral-600">Clear done</button>
        </form>
      </div>
    </div>

    <div class="flex gap-3 items-center py-3 px-4 bg-neutral-950 border border-dashed border-neutral-800 mb-px transition-colors focus-within:border-neutral-600 focus-within:border-solid focus-within:bg-neutral-900">
      <form class="flex-1 flex gap-2" hx-post="/tasks" hx-target="#main-content" hx-swap="innerHTML">
        <input type="hidden" name="q" value={@search} />
        <input type="hidden" name="status" value={@status_filter} />
        <input type="text" name="title" placeholder="Add task... (Enter)" autofocus
               class="flex-1 py-2 bg-transparent border-none text-neutral-200 text-[15px] placeholder-neutral-600 focus:outline-none" />
        <button type="submit" class="bg-transparent border-none text-neutral-600 cursor-pointer px-2 text-xl leading-none opacity-70 hover:text-green-500 hover:opacity-100" aria-label="Add" title="Add task">+</button>
      </form>
    </div>

    <div id="task-list" class="flex flex-col gap-px">
      <div :if={@tasks == []} class="py-16 px-8 text-center text-neutral-600 text-[15px]">
        <p>No tasks yet. Type above and press Enter to add one.</p>
      </div>
      {@task_rows}
    </div>
    """)
  end

  def render_task_row(task, editing \\ false) do
    assigns = %{
      task: task,
      time_ago: time_ago(task.created_at),
      priority_high: (task.priority || "normal") == "high",
      editing: editing
    }

    FrancisHtmx.rendered_to_string(~H"""
    <div id={"task-#{@task.id}"} class={"flex items-center gap-3 py-3.5 px-4 bg-neutral-950/80 border border-neutral-800 transition-all hover:bg-neutral-900 group #{if @task.done, do: "opacity-50", else: ""}"}>
      <form hx-patch={"/tasks/#{@task.id}/toggle"} hx-target={"#task-#{@task.id}"} hx-swap="outerHTML">
        <button type="submit" class="bg-transparent border-none cursor-pointer p-1 leading-none text-neutral-600 transition-colors hover:text-neutral-500" aria-label="Toggle done">
          <span :if={@task.done} class="text-green-500"><Heroicons.check_circle solid class="w-5 h-5 shrink-0" /></span>
          <span :if={!@task.done} class="text-neutral-600"><Heroicons.check_circle class="w-5 h-5 shrink-0" /></span>
        </button>
      </form>
      <div class="flex-1">
        <form :if={@editing} hx-put={"/tasks/#{@task.id}"} hx-target={"#task-#{@task.id}"} hx-swap="outerHTML"
              hx-trigger="blur from:input delay:150ms, keyup[key=='Enter'] from:input">
          <input type="text" name="title" value={@task.title} autofocus
                 class="w-full py-1 bg-transparent border-none text-inherit font-inherit focus:outline-none" />
        </form>
        <span :if={!@editing} class={"block text-[15px] cursor-pointer transition-colors hover:text-neutral-200 #{if @task.done, do: "line-through text-neutral-600", else: if(@priority_high, do: "text-neutral-200", else: "text-neutral-400")}"}
              hx-get={"/tasks/#{@task.id}/edit"} hx-target={"#task-#{@task.id}"} hx-swap="outerHTML" hx-trigger="click once">{@task.title}</span>
        <span class="text-xs text-neutral-700 mt-1">{@time_ago}</span>
      </div>
      <div class="flex items-center gap-1 opacity-60 group-hover:opacity-100">
        <form hx-patch={"/tasks/#{@task.id}/priority"} hx-target={"#task-#{@task.id}"} hx-swap="outerHTML">
          <button type="submit" class={"bg-transparent border-none cursor-pointer p-1 leading-none transition-colors #{if @priority_high, do: "text-yellow-500", else: "text-neutral-600 hover:text-neutral-500"}"} aria-label="Star" title={if @priority_high, do: "Unstar", else: "Star"}>★</button>
        </form>
        <form hx-delete={"/tasks/#{@task.id}"} hx-target="#main-content" hx-swap="innerHTML" hx-confirm="Delete this task?">
          <button type="submit" class="bg-transparent text-neutral-500 border border-neutral-800 py-1.5 px-3 rounded-md cursor-pointer text-[13px] transition-all hover:text-red-400 hover:border-red-900/50" aria-label="Delete">×</button>
        </form>
      </div>
    </div>
    """)
  end

  defp extract_filters(params) do
    search = Map.get(params, "q", "")
    status_filter = Map.get(params, "status", "all")
    {search, status_filter}
  end

  defp nillify(""), do: nil
  defp nillify(val), do: val

  defp nillify_status(status) when status in ["done", "todo"], do: status
  defp nillify_status(_), do: nil

  defp time_ago(iso8601) when is_binary(iso8601) do
    case DateTime.from_iso8601(iso8601) do
      {:ok, dt, _} ->
        diff_sec = DateTime.diff(DateTime.utc_now(), dt, :second)

        cond do
          diff_sec < 60 -> "now"
          diff_sec < 3600 -> "#{div(diff_sec, 60)}m ago"
          diff_sec < 86400 -> "#{div(diff_sec, 3600)}h ago"
          diff_sec < 604_800 -> "#{div(diff_sec, 86400)}d ago"
          true -> "#{div(diff_sec, 604_800)}w ago"
        end

      _ ->
        ""
    end
  end

  defp time_ago(_), do: ""
end
