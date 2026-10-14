defmodule CrsftwreTest.Commands.Sorter do
  alias CrsftwreTest.Commands.Command

  @moduledoc "Kahn's algorithm"

  @spec sort([Command.t()]) :: {:ok, [Command.t()]} | {:error, [String.t()]}
  def sort([]), do: {:ok, []}

  def sort(commands) do
    {queue, in_degrees} =
      Enum.reduce(commands, {:queue.new(), %{}}, fn %Command{} = cmd, {queue, in_degrees} ->
        case length(cmd.requires) do
          0 -> {:queue.in(cmd, queue), in_degrees}
          len -> {queue, Map.put(in_degrees, cmd.name, len)}
        end
      end)

    edges =
      Enum.reduce(commands, %{}, fn %Command{} = cmd, edges ->
        Enum.reduce(cmd.requires, edges, fn requirement, edges ->
          Map.update(edges, requirement, [cmd], &[cmd | &1])
        end)
      end)

    case sort(queue, in_degrees, edges, []) do
      {in_degrees, sorted} when map_size(in_degrees) == 0 ->
        {:ok, sorted}

      {in_degrees, _sorted} ->
        {:error, to_errors(in_degrees)}
    end
  end

  defp sort(queue, in_degrees, edges, sorted) do
    case :queue.out(queue) do
      {{:value, %Command{} = cmd}, new_queue} ->
        dependants = Map.get(edges, cmd.name, [])
        {new_queue, in_degrees} = enqueue_resolved(dependants, new_queue, in_degrees)
        sort(new_queue, in_degrees, edges, [cmd | sorted])

      {:empty, _} ->
        {in_degrees, Enum.reverse(sorted)}
    end
  end

  defp enqueue_resolved(dependants, queue, in_degrees) do
    dependants
    |> Enum.reduce({queue, in_degrees}, fn dependant, {queue, in_degrees} = state ->
      case Map.get(in_degrees, dependant.name) do
        nil ->
          state

        1 ->
          {:queue.in(dependant, queue), Map.delete(in_degrees, dependant.name)}

        in_degree ->
          {queue, %{in_degrees | dependant.name => in_degree - 1}}
      end
    end)
  end

  defp to_errors(in_degrees) do
    Enum.map(in_degrees, fn {name, count} ->
      "Couldn't resolve #{count} deps for task #{name}"
    end)
  end
end
