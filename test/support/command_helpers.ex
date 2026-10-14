defmodule CrsftwreTest.CommandHelpers do
  @moduledoc """
  Helpers for building and asserting on `CrsftwreTest.Commands.Command` lists in tests.
  """

  import ExUnit.Assertions

  alias CrsftwreTest.Commands.Command

  def cmd(name, requires \\ []) do
    %Command{name: name, command: "echo #{name}", requires: requires}
  end

  def names(commands), do: Enum.map(commands, & &1.name)

  def assert_valid_order(sorted, input) do
    assert Enum.sort(names(sorted)) == Enum.sort(names(input))

    positions = sorted |> names() |> Enum.with_index() |> Map.new()

    for %Command{name: name, requires: requires} <- sorted, req <- requires do
      assert positions[req] < positions[name],
             "expected #{req} to come before #{name}, got: #{inspect(names(sorted))}"
    end
  end
end
