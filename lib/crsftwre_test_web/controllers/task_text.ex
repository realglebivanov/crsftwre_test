defmodule CrsftwreTestWeb.Controllers.TaskTEXT do
  @moduledoc false

  alias CrsftwreTest.Commands.Command

  @doc """
  Renders the sorted tasks as a bash script.
  """
  @spec format(%{commands: [Command.t()]}) :: iolist()
  def format(%{commands: commands}) do
    ["#!/usr/bin/env bash\n" | Enum.map(commands, &line/1)]
  end

  defp line(%Command{} = command), do: [command.command, ?\n]
end
