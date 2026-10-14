defmodule CrsftwreTest.CommandHelpers do
  @moduledoc """
  Helpers for building and asserting on `CrsftwreTest.Commands.Command` lists in tests.
  """

  import ExUnit.Assertions

  alias CrsftwreTest.Commands.Command

  @spec cmd(String.t(), [String.t()]) :: Command.t()
  def cmd(name, requires \\ []) do
    %Command{name: name, command: "echo #{name}", requires: requires}
  end

  @spec names([Command.t()]) :: [String.t()]
  def names(commands), do: Enum.map(commands, & &1.name)

  @spec assert_valid_order([Command.t()], [Command.t()]) :: :ok
  def assert_valid_order(sorted, input) do
    assert Enum.sort(names(sorted)) == Enum.sort(names(input))

    positions = sorted |> names() |> Enum.with_index() |> Map.new()

    for %Command{name: name, requires: requires} <- sorted, req <- requires do
      assert positions[req] < positions[name],
             "expected #{req} to come before #{name}, got: #{inspect(names(sorted))}"
    end

    :ok
  end
end
