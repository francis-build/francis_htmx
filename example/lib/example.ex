defmodule Example do
  use Francis

  use FrancisHtmx,
    title: "HTMX Example",
    head: ~E"""
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
               max-width: 40rem; margin: 2rem auto; padding: 0 1rem; color: #212529; }
        h1 { margin-bottom: 1.5rem; }
        .card { border: 1px solid #dee2e6; border-radius: 0.5rem; padding: 1.5rem; margin-bottom: 1rem; }
        .card h2 { margin-top: 0; }
        .smooth { transition: all 1s ease-in; font-size: 4rem; }
        input { padding: 0.4rem 0.8rem; font-size: 1rem; border: 1px solid #ced4da; border-radius: 0.25rem; }
        button { padding: 0.4rem 0.8rem; font-size: 1rem; cursor: pointer;
                 background: #212529; color: white; border: none; border-radius: 0.25rem; }
        #greeting { margin-top: 0.5rem; }
        #time { font-size: 1.25rem; font-variant-numeric: tabular-nums; }
      </style>
    """

  htmx(fn _conn ->
    ~E"""
    <h1>FrancisHtmx Demo</h1>

    <div class="card">
      <h2>Color Swap</h2>
      <p>Polls <code>/colors</code> every second via <code>hx-trigger</code>.</p>
      <div hx-get="/colors" hx-trigger="every 1s">
        <p id="color-demo" class="smooth">Color Swap Demo</p>
      </div>
    </div>

    <div class="card">
      <h2>Greeting Form</h2>
      <p>Submits via <code>hx-post</code> and swaps the result into <code>#greeting</code>.</p>
      <form hx-post="/greet" hx-target="#greeting" hx-swap="innerHTML">
        <input type="text" name="name" placeholder="Your name" />
        <button type="submit">Greet</button>
      </form>
      <div id="greeting"></div>
    </div>

    <div class="card">
      <h2>Server Time</h2>
      <p>Loads once on page load via <code>hx-trigger="load"</code>.</p>
      <div id="time" hx-get="/time" hx-trigger="load, every 5s"></div>
    </div>
    """
  end)

  get("/colors", fn _ ->
    new_color = 3 |> :crypto.strong_rand_bytes() |> Base.encode16() |> then(&"##{&1}")
    assigns = %{new_color: new_color}

    ~E"""
    <p id="color-demo" class="smooth" style="<%= "color:#{@new_color}" %>">
    Color Swap Demo
    </p>
    """
  end)

  post("/greet", fn conn ->
    name = conn.params["name"] || "World"
    assigns = %{name: name}

    ~E"""
    <p>Hello, <strong><%= @name %></strong>!</p>
    """
  end)

  get("/time", fn _ ->
    now = DateTime.utc_now() |> Calendar.strftime("%H:%M:%S UTC")
    assigns = %{now: now}

    ~E"""
    <p><%= @now %></p>
    """
  end)
end
