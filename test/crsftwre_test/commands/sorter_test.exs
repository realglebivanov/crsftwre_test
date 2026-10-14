defmodule CrsftwreTest.Commands.SorterTest do
  use ExUnit.Case, async: true

  import CrsftwreTest.CommandHelpers

  alias CrsftwreTest.Commands.Sorter

  test "returns an empty list for no commands" do
    assert {:ok, []} = Sorter.sort([])
  end

  test "returns a single command without requirements" do
    command = cmd("task-1")
    assert {:ok, [^command]} = Sorter.sort([command])
  end

  test "keeps input order for independent commands" do
    commands = [cmd("task-1"), cmd("task-2"), cmd("task-3")]
    assert {:ok, ^commands} = Sorter.sort(commands)
  end

  test "keeps input order when already sorted" do
    commands = [cmd("task-1"), cmd("task-2", ["task-1"]), cmd("task-3", ["task-2"])]
    assert {:ok, ^commands} = Sorter.sort(commands)
  end

  test "moves a command after its requirement" do
    commands = [cmd("task-2", ["task-1"]), cmd("task-1")]
    assert {:ok, sorted} = Sorter.sort(commands)
    assert names(sorted) == ["task-1", "task-2"]
  end

  test "keeps input order for commands unblocked by the same requirement" do
    commands = [cmd("a"), cmd("b", ["a"]), cmd("c", ["a"]), cmd("d", ["a"])]
    assert {:ok, ^commands} = Sorter.sort(commands)
  end

  test "sorts a reversed chain" do
    commands = [cmd("task-3", ["task-2"]), cmd("task-2", ["task-1"]), cmd("task-1")]
    assert {:ok, sorted} = Sorter.sort(commands)
    assert names(sorted) == ["task-1", "task-2", "task-3"]
  end

  test "sorts the example from the task description" do
    commands = [
      cmd("task-1"),
      cmd("task-2", ["task-3"]),
      cmd("task-3", ["task-1"]),
      cmd("task-4", ["task-2", "task-3"])
    ]

    assert {:ok, sorted} = Sorter.sort(commands)
    assert names(sorted) == ["task-1", "task-3", "task-2", "task-4"]
  end

  test "handles a command with multiple requirements declared before them" do
    commands = [cmd("task-3", ["task-1", "task-2"]), cmd("task-1"), cmd("task-2")]
    assert {:ok, sorted} = Sorter.sort(commands)
    assert_valid_order(sorted, commands)
  end

  test "handles a diamond dependency graph" do
    commands = [
      cmd("d", ["b", "c"]),
      cmd("c", ["a"]),
      cmd("b", ["a"]),
      cmd("a")
    ]

    assert {:ok, sorted} = Sorter.sort(commands)
    assert_valid_order(sorted, commands)
  end

  test "handles a deferred command unblocked by another deferred command" do
    commands = [cmd("c", ["b"]), cmd("b", ["a"]), cmd("x"), cmd("a")]
    assert {:ok, sorted} = Sorter.sort(commands)
    assert_valid_order(sorted, commands)
  end

  test "handles a chain that needs several passes over deferred commands" do
    commands = [cmd("b", ["a"]), cmd("c", ["b"]), cmd("a"), cmd("e", ["d"]), cmd("d", ["c"])]
    assert {:ok, sorted} = Sorter.sort(commands)
    assert_valid_order(sorted, commands)
  end

  test "preserves the command structs unchanged" do
    commands = [cmd("task-2", ["task-1"]), cmd("task-1")]
    assert {:ok, sorted} = Sorter.sort(commands)
    assert Enum.sort(sorted) == Enum.sort(commands)
  end

  test "returns an error for a missing requirement" do
    assert {:error, errors} = Sorter.sort([cmd("task-1", ["missing"])])
    assert errors == ["Couldn't resolve 1 deps for task task-1"]
  end

  test "reports every task with a missing requirement" do
    commands = [
      cmd("task-1"),
      cmd("task-2", ["missing-1", "task-1"]),
      cmd("task-3", ["missing-2"])
    ]

    assert {:error, errors} = Sorter.sort(commands)

    assert Enum.sort(errors) == [
             "Couldn't resolve 1 deps for task task-2",
             "Couldn't resolve 1 deps for task task-3"
           ]
  end

  test "reports every task sharing a missing requirement" do
    commands = [cmd("task-1", ["missing"]), cmd("task-2", ["missing"])]
    assert {:error, errors} = Sorter.sort(commands)

    assert Enum.sort(errors) == [
             "Couldn't resolve 1 deps for task task-1",
             "Couldn't resolve 1 deps for task task-2"
           ]
  end

  test "reports tasks that depend on an unresolved task" do
    commands = [cmd("task-1", ["missing"]), cmd("task-2", ["task-1"])]
    assert {:error, errors} = Sorter.sort(commands)

    assert Enum.sort(errors) == [
             "Couldn't resolve 1 deps for task task-1",
             "Couldn't resolve 1 deps for task task-2"
           ]
  end

  test "does not report tasks or deps that were resolved before failing" do
    commands = [cmd("b", ["a"]), cmd("c", ["b"]), cmd("a"), cmd("d", ["c", "missing"])]
    assert {:error, errors} = Sorter.sort(commands)
    assert errors == ["Couldn't resolve 1 deps for task d"]
  end

  test "returns an error when a command requires itself" do
    assert {:error, errors} = Sorter.sort([cmd("task-1", ["task-1"])])
    assert errors == ["Couldn't resolve 1 deps for task task-1"]
  end

  test "returns an error for a dependency cycle" do
    commands = [cmd("task-1", ["task-2"]), cmd("task-2", ["task-1"])]
    assert {:error, errors} = Sorter.sort(commands)

    assert Enum.sort(errors) == [
             "Couldn't resolve 1 deps for task task-1",
             "Couldn't resolve 1 deps for task task-2"
           ]
  end

  test "returns an error for a cycle alongside valid commands" do
    commands = [cmd("a"), cmd("b", ["c"]), cmd("c", ["b"]), cmd("d", ["a"])]
    assert {:error, errors} = Sorter.sort(commands)

    assert Enum.sort(errors) == [
             "Couldn't resolve 1 deps for task b",
             "Couldn't resolve 1 deps for task c"
           ]
  end
end
