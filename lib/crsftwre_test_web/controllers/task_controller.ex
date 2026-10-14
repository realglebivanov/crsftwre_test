defmodule CrsftwreTestWeb.Controllers.TaskController do
  alias CrsftwreTest.Commands

  use CrsftwreTestWeb, :controller

  plug :accepts, ["json", "text"]

  action_fallback CrsftwreTestWeb.Controllers.FallbackController

  def format(conn, params) do
    with {:ok, commands} <- Commands.Parser.parse(params),
         {:ok, commands} <- Commands.Sorter.sort(commands) do
      render(conn, :format, commands: commands)
    end
  end
end
