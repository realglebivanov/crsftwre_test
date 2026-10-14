defmodule CrsftwreTest.Commands.Parser do
  @moduledoc """
  Validates a decoded tasks payload against `priv/schemas/tasks.json`
  and turns it into a list of `CrsftwreTest.Commands.Command` structs.
  """

  alias CrsftwreTest.Commands.Command

  @schema_path Application.app_dir(:crsftwre_test, "priv/schemas/tasks.json")
  @external_resource @schema_path
  @schema @schema_path |> File.read!() |> Jason.decode!() |> ExJsonSchema.Schema.resolve()

  @type error :: %{path: String.t(), message: String.t()}

  @spec parse(map()) :: {:ok, [Command.t()]} | {:error, [error()]}
  def parse(data) do
    case ExJsonSchema.Validator.validate(@schema, data) do
      :ok ->
        {:ok, Enum.map(data["tasks"], &to_command/1)}

      {:error, errors} ->
        {:error, Enum.map(errors, fn {message, path} -> %{path: path, message: message} end)}
    end
  end

  defp to_command(task) do
    %Command{
      name: task["name"],
      command: task["command"],
      requires: Map.get(task, "requires", [])
    }
  end
end
