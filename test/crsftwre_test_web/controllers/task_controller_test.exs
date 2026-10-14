defmodule CrsftwreTestWeb.Controllers.TaskControllerTest do
  use CrsftwreTestWeb.ConnCase, async: true

  @payload %{
    "tasks" => [
      %{"name" => "task-1", "command" => "touch /tmp/file1"},
      %{"name" => "task-2", "command" => "cat /tmp/file1", "requires" => ["task-3"]},
      %{
        "name" => "task-3",
        "command" => "echo 'Hello World!' > /tmp/file1",
        "requires" => ["task-1"]
      },
      %{"name" => "task-4", "command" => "rm /tmp/file1", "requires" => ["task-2", "task-3"]}
    ]
  }

  defp post_tasks(conn, payload, accept \\ "application/json") do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", accept)
    |> post(~p"/tasks/format", Jason.encode!(payload))
  end

  describe "POST /tasks/format as text" do
    test "returns a bash script in dependency order", %{conn: conn} do
      assert text_response(post_tasks(conn, @payload, "text/plain"), 200) == """
             #!/usr/bin/env bash
             touch /tmp/file1
             echo 'Hello World!' > /tmp/file1
             cat /tmp/file1
             rm /tmp/file1
             """
    end

    test "returns only the shebang for no tasks", %{conn: conn} do
      assert text_response(post_tasks(conn, %{"tasks" => []}, "text/plain"), 200) ==
               "#!/usr/bin/env bash\n"
    end
  end

  describe "POST /tasks/format" do
    test "defaults to json when any format is accepted", %{conn: conn} do
      assert %{"tasks" => [_, _, _, _]} = json_response(post_tasks(conn, @payload, "*/*"), 200)
    end

    test "returns tasks in dependency order", %{conn: conn} do
      assert json_response(post_tasks(conn, @payload), 200) == %{
               "tasks" => [
                 %{"name" => "task-1", "command" => "touch /tmp/file1"},
                 %{"name" => "task-3", "command" => "echo 'Hello World!' > /tmp/file1"},
                 %{"name" => "task-2", "command" => "cat /tmp/file1"},
                 %{"name" => "task-4", "command" => "rm /tmp/file1"}
               ]
             }
    end

    test "returns an empty list for no tasks", %{conn: conn} do
      assert json_response(post_tasks(conn, %{"tasks" => []}), 200) == %{"tasks" => []}
    end

    test "returns 422 with schema errors for an invalid payload", %{conn: conn} do
      payload = %{"tasks" => [%{"name" => "task-1"}]}

      assert %{"errors" => [%{"path" => "#/tasks/0", "message" => message}]} =
               json_response(post_tasks(conn, payload), 422)

      assert message =~ "command"
    end

    test "returns 422 when tasks form a cycle", %{conn: conn} do
      payload = %{
        "tasks" => [
          %{"name" => "a", "command" => "echo a", "requires" => ["b"]},
          %{"name" => "b", "command" => "echo b", "requires" => ["a"]}
        ]
      }

      assert %{"errors" => errors} = json_response(post_tasks(conn, payload), 422)

      assert Enum.sort(errors) == [
               "Couldn't resolve 1 deps for task a",
               "Couldn't resolve 1 deps for task b"
             ]
    end

    test "returns 422 when a task requires an unknown task", %{conn: conn} do
      payload = %{
        "tasks" => [%{"name" => "a", "command" => "echo a", "requires" => ["missing"]}]
      }

      assert json_response(post_tasks(conn, payload), 422) == %{
               "errors" => ["Couldn't resolve 1 deps for task a"]
             }
    end
  end
end
