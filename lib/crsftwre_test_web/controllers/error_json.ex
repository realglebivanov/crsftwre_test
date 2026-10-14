defmodule CrsftwreTestWeb.ErrorJSON do
  @moduledoc false

  @spec render(String.t(), map()) :: %{errors: [String.t()]}
  def render(template, _assigns) do
    %{errors: [Phoenix.Controller.status_message_from_template(template)]}
  end
end
