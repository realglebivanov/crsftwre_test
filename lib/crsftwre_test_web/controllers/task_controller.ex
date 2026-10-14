defmodule CrsftwreTestWeb.Controllers.TaskController do
  use CrsftwreTestWeb, :controller

  alias CrsftwreTest.Commands

  plug :accepts, ["json", "text"]

  action_fallback CrsftwreTestWeb.Controllers.FallbackController

  @spec format(Plug.Conn.t(), map()) ::
          Plug.Conn.t() | {:error, [Commands.Parser.error()] | [String.t()]}
  def format(conn, params) do
    with {:ok, commands} <- Commands.Parser.parse(params),
         {:ok, commands} <- Commands.Sorter.sort(commands) do
      render(conn, :format, commands: commands)
    end
  end
end
