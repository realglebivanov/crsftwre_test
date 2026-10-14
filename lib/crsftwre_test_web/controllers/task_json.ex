defmodule CrsftwreTestWeb.Controllers.TaskJSON do
  alias CrsftwreTest.Commands.Command

  @doc """
  Renders the sorted tasks.
  """
  def format(%{commands: commands}) do
    %{tasks: Enum.map(commands, &data/1)}
  end

  defp data(%Command{} = command) do
    %{name: command.name, command: command.command}
  end
end
