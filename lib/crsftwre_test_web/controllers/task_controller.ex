defmodule CrsftwreTestWeb.Controllers.TaskController do
  use CrsftwreTestWeb, :controller

  alias CrsftwreTest.Commands

  action_fallback CrsftwreTestWeb.Controllers.FallbackController

  def format(conn, params) do
    with {:ok, commands} <- Commands.Parser.parse(params),
         {:ok, commands} <- Commands.Sorter.sort(commands) do
      commands =
        Enum.map(commands, fn %Commands.Command{} = cmd ->
          cmd.command
        end)

      render(conn, :format, commands: commands)
    end
  end
end
