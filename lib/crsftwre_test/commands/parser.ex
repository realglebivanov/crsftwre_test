defmodule CrsftwreTest.Commands.Parser do
  @moduledoc """
  Validates a decoded tasks payload against `priv/schemas/tasks.json`
  and turns it into a list of `CrsftwreTest.Commands.Command` structs.
  """

  alias CrsftwreTest.Commands.Command

  @schema_path Application.app_dir(:crsftwre_test, "priv/schemas/tasks.json")
  @external_resource @schema_path
  @schema @schema_path |> File.read!() |> Jason.decode!() |> ExJsonSchema.Schema.resolve()

  @type error :: %{path: String.t(), message: String.t()} | String.t()

  @spec parse(map()) :: {:ok, [Command.t()]} | {:error, [error()]}
  def parse(data) do
    case ExJsonSchema.Validator.validate(@schema, data) do
      :ok ->
        to_commands(data["tasks"])

      {:error, errors} ->
        {:error, Enum.map(errors, fn {message, path} -> %{path: path, message: message} end)}
    end
  end

  defp to_commands(tasks) do
    tasks
    |> Enum.reduce({MapSet.new(), [], []}, fn task, {met, tasks, errors} ->
      if MapSet.member?(met, task["name"]) do
        {met, tasks, ["Found duplicate task #{task["name"]}" | errors]}
      else
        {MapSet.put(met, task["name"]), [to_command(task) | tasks], errors}
      end
    end)
    |> case do
      {_met, tasks, []} -> {:ok, Enum.reverse(tasks)}
      {_met, _tasks, errors} -> {:error, Enum.reverse(errors)}
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
