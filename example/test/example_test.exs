defmodule ExampleTest do
  use ExUnit.Case
  import Plug.Conn

  describe "GET /" do
    test "renders full page with HTMX and navigation for direct access" do
      response = Req.get!("/", plug: Example)

      assert response.status == 200
      assert response.headers["content-type"] == ["text/html; charset=utf-8"]

      html = Floki.parse_document!(response.body)

      assert html |> Floki.find("title") |> Floki.text() =~ "Taskflow"

      scripts = Floki.find(html, "script") |> Floki.attribute("src")
      assert "https://unpkg.com/htmx.org@2" in scripts

      assert [{"nav", _, _}] = Floki.find(html, "nav")
      assert [{"div", _, _}] = Floki.find(html, "#main-content")
    end

    test "returns task list content for HTMX request" do
      conn =
        :get
        |> Plug.Test.conn("/")
        |> put_req_header("hx-request", "true")
        |> Example.call([])

      assert conn.status == 200
      assert conn.resp_body =~ "task-list"
      assert conn.resp_body =~ "Tasks"
    end
  end

  describe "POST /tasks" do
    test "creates a task and returns updated list" do
      conn =
        :post
        |> Plug.Test.conn("/tasks", "title=Test+Task")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> put_req_header("hx-request", "true")
        |> Example.call([])

      assert conn.status == 200
      assert conn.resp_body =~ "Test Task"
      assert conn.resp_body =~ "task-list"
    end
  end

  describe "GET /tasks/new" do
    test "renders add task form with HTMX request" do
      conn =
        :get
        |> Plug.Test.conn("/tasks/new")
        |> put_req_header("hx-request", "true")
        |> Example.call([])

      assert conn.status == 200
      assert conn.resp_body =~ "Add"
      assert conn.resp_body =~ "hx-post"
      assert conn.resp_body =~ "What needs to be done"
    end

    test "renders full page for direct access" do
      conn =
        :get
        |> Plug.Test.conn("/tasks/new")
        |> Example.call([])

      assert conn.status == 200
      assert conn.resp_body =~ "Taskflow"
      assert conn.resp_body =~ "main-content"
    end
  end

  describe "DELETE /tasks/:id" do
    test "deletes task" do
      # First create a task
      conn =
        :post
        |> Plug.Test.conn("/tasks", "title=To+Delete")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> Example.call([])

      assert conn.status == 200
      assert conn.resp_body =~ "To Delete"

      # Find the task row containing "To Delete" and extract its id
      html = Floki.parse_document!(conn.resp_body)
      matching =
        Floki.find(html, "div[id^='task-']")
        |> Enum.filter(fn d ->
          [id] = Floki.attribute(d, "id")
          id != "task-list" and Floki.text(d) =~ "To Delete"
        end)

      assert [task_div] = matching
      [id] = Floki.attribute(task_div, "id")
      id = String.replace(id, "task-", "")

      # Delete it
      conn =
        :delete
        |> Plug.Test.conn("/tasks/#{id}")
        |> put_req_header("hx-request", "true")
        |> Example.call([])

      assert conn.status == 200
      refute conn.resp_body =~ "To Delete"
    end
  end
end
