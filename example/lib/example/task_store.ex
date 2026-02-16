defmodule Example.TaskStore do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{tasks: [], next_id: 1} end, name: __MODULE__)
  end

  def list_tasks(opts \\ []) do
    Agent.get(__MODULE__, fn state ->
      state.tasks
      |> filter_by_query(Keyword.get(opts, :q))
      |> filter_by_status(Keyword.get(opts, :status))
      |> sort_tasks()
    end)
  end

  def get_task(id) do
    id = to_id(id)
    Agent.get(__MODULE__, fn state -> Enum.find(state.tasks, &(&1.id == id)) end)
  end

  def count_by_status do
    Agent.get(__MODULE__, fn state ->
      total = length(state.tasks)
      done = Enum.count(state.tasks, & &1.done)
      %{total: total, done: done, todo: total - done}
    end)
  end

  def add_task(attrs) do
    Agent.update(__MODULE__, fn state ->
      task = %{
        id: state.next_id,
        title: attrs["title"] || attrs[:title] || "",
        done: false,
        priority: attrs["priority"] || attrs[:priority] || "normal",
        created_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      %{state | tasks: [task | state.tasks], next_id: state.next_id + 1}
    end)
  end

  def update_task(id, attrs) do
    update_by_id(id, fn task ->
      task
      |> maybe_update(:title, attrs["title"] || attrs[:title])
      |> maybe_update(:priority, attrs["priority"] || attrs[:priority])
    end)
  end

  def toggle_task(id) do
    update_by_id(id, fn task -> %{task | done: !task.done} end)
  end

  def toggle_priority(id) do
    update_by_id(id, fn task ->
      new_priority = if (task.priority || "normal") == "high", do: "normal", else: "high"
      %{task | priority: new_priority}
    end)
  end

  def delete_task(id) do
    id = to_id(id)
    Agent.update(__MODULE__, fn state ->
      %{state | tasks: Enum.reject(state.tasks, &(&1.id == id))}
    end)
  end

  def mark_all_done do
    Agent.update(__MODULE__, fn state ->
      %{state | tasks: Enum.map(state.tasks, &%{&1 | done: true})}
    end)
  end

  def mark_all_todo do
    Agent.update(__MODULE__, fn state ->
      %{state | tasks: Enum.map(state.tasks, &%{&1 | done: false})}
    end)
  end

  def clear_completed do
    Agent.update(__MODULE__, fn state ->
      %{state | tasks: Enum.reject(state.tasks, & &1.done)}
    end)
  end

  # --- Private ---

  defp update_by_id(id, update_fn) do
    id = to_id(id)

    Agent.update(__MODULE__, fn state ->
      tasks = Enum.map(state.tasks, fn t -> if t.id == id, do: update_fn.(t), else: t end)
      %{state | tasks: tasks}
    end)
  end

  defp to_id(id) when is_binary(id), do: String.to_integer(id)
  defp to_id(id) when is_integer(id), do: id

  defp filter_by_query(tasks, nil), do: tasks
  defp filter_by_query(tasks, ""), do: tasks

  defp filter_by_query(tasks, query) do
    q = String.downcase(query)
    Enum.filter(tasks, fn t -> String.contains?(String.downcase(t.title), q) end)
  end

  defp filter_by_status(tasks, nil), do: tasks
  defp filter_by_status(tasks, "done"), do: Enum.filter(tasks, & &1.done)
  defp filter_by_status(tasks, "todo"), do: Enum.filter(tasks, &(!&1.done))
  defp filter_by_status(tasks, _), do: tasks

  @priority_order %{"high" => 0, "normal" => 1, "low" => 2}

  defp sort_tasks(tasks) do
    Enum.sort(tasks, fn t1, t2 ->
      p1 = Map.get(@priority_order, t1.priority || "normal", 1)
      p2 = Map.get(@priority_order, t2.priority || "normal", 1)

      if p1 != p2, do: p1 < p2, else: t1.created_at >= t2.created_at
    end)
  end

  defp maybe_update(task, _key, nil), do: task
  defp maybe_update(task, :title, val) when is_binary(val), do: %{task | title: val}
  defp maybe_update(task, :priority, val) when is_binary(val), do: %{task | priority: val}
  defp maybe_update(task, _key, _), do: task
end
