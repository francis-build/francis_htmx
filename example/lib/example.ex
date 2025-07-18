defmodule Example do
  use Francis
  use FrancisHtmx, version: "2", title: "HTMX Example"

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
