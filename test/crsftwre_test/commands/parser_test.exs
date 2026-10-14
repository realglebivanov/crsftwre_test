defmodule CrsftwreTest.Commands.ParserTest do
  use ExUnit.Case, async: true

  alias CrsftwreTest.Commands.{Command, Parser}

  test "parses valid tasks into commands" do
    data = %{
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

    assert {:ok,
            [
              %Command{name: "task-1", command: "touch /tmp/file1", requires: []},
              %Command{name: "task-2", command: "cat /tmp/file1", requires: ["task-3"]},
              %Command{
                name: "task-3",
                command: "echo 'Hello World!' > /tmp/file1",
                requires: ["task-1"]
              },
              %Command{name: "task-4", command: "rm /tmp/file1", requires: ["task-2", "task-3"]}
            ]} = Parser.parse(data)
  end

  test "rejects missing tasks key" do
    assert {:error, [%{path: "#", message: message}]} = Parser.parse(%{})
    assert message =~ "tasks"
  end

  test "rejects a task without a command" do
    assert {:error, [%{path: "#/tasks/0"}]} =
             Parser.parse(%{"tasks" => [%{"name" => "task-1"}]})
  end

  test "rejects wrong types and unknown fields" do
    assert {:error, errors} =
             Parser.parse(%{
               "tasks" => [
                 %{"name" => 1, "command" => "ls", "requires" => "task-2", "extra" => true}
               ]
             })

    paths = Enum.map(errors, & &1.path)
    assert "#/tasks/0/name" in paths
    assert "#/tasks/0/requires" in paths
    assert "#/tasks/0/extra" in paths
  end
end
