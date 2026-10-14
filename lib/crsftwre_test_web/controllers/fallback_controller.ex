defmodule CrsftwreTestWeb.Controllers.FallbackController do
  use CrsftwreTestWeb, :controller

  @spec call(Plug.Conn.t(), {:error, [term()]}) :: Plug.Conn.t()
  def call(conn, {:error, errors}) when is_list(errors) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: errors})
  end
end
