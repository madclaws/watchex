defmodule Watchex.Gameplay.Utils.GridManager do
  @moduledoc """
  Contains core functions for handling the world grid
  """

  @grid_width 10
  @grid_height 10

  @wall_cell 1

  alias Watchex.Gameplay.Utils.Position

  @doc """
  Returns the world grid map
  """
  @spec get_world_grid() :: map()
  def get_world_grid do
    grid =
      File.read!("#{:code.priv_dir(:watchex)}/assets/json/world.json")
      |> Jason.decode!()

    convert_grid_to_map(grid["world"])
  end

  @spec get_random_position(gridmap :: map()) :: Position.t()
  def get_random_position(gridmap) do
    rand_row = Enum.random(0..(@grid_height - 1))
    rand_col = Enum.random(0..(@grid_width - 1))

    if gridmap[rand_row][rand_col] !== @wall_cell do
      Position.new(rand_row, rand_col)
    else
      get_random_position(gridmap)
    end
  end

  @spec move_on_grid(map(), Position.t(), String.t()) :: Position.t()
  def move_on_grid(gridmap, position, "Left") do
    new_position = Position.new(position.row, position.col - 1)
    get_new_position(gridmap[new_position.row][new_position.col], new_position, position)
  end

  def move_on_grid(gridmap, position, "Right") do
    new_position = Position.new(position.row, position.col + 1)
    get_new_position(gridmap[new_position.row][new_position.col], new_position, position)
  end

  def move_on_grid(gridmap, position, "Up") do
    new_position = Position.new(position.row - 1, position.col)
    get_new_position(gridmap[new_position.row][new_position.col], new_position, position)
  end

  def move_on_grid(gridmap, position, "Down") do
    new_position = Position.new(position.row + 1, position.col)
    get_new_position(gridmap[new_position.row][new_position.col], new_position, position)
  end

  @spec get_attackable_positions(Position.t()) :: list(Position.t())
  def get_attackable_positions(attack_position) do
    current_row = attack_position.row
    current_col = attack_position.col

    for row <- (current_row - 1)..(current_row + 1),
        col <- (current_col - 1)..(current_col + 1) do
      Position.new(row, col)
    end
  end

  @spec get_new_position(tile_type :: number(), Position.t(), Position.t()) :: Position.t()
  defp get_new_position(nil, _new_position, old_position), do: old_position
  defp get_new_position(1, _new_position, old_position), do: old_position
  defp get_new_position(_, new_position, _old_position), do: new_position

  # gridMatrix will be a nested map, becuase that will give us O(1) access to elements in it,
  # unlike list in Elixir
  @spec convert_grid_to_map(list(), index :: number(), gridmap :: map()) :: map()
  defp convert_grid_to_map(world_list, index \\ 0, gridmap \\ %{})
  defp convert_grid_to_map([], _index, gridmap), do: gridmap

  defp convert_grid_to_map([h | t], index, gridmap) do
    convert_row_to_map(h)
    |> then(&Map.update(gridmap, index, &1, fn _ -> &1 end))
    |> then(&convert_grid_to_map(t, index + 1, &1))
  end

  # Converting each individual row to map.
  @spec convert_row_to_map(row :: list(), index :: number(), row_map :: map()) :: map()
  defp convert_row_to_map(row, index \\ 0, row_map \\ %{})
  defp convert_row_to_map([], _index, row_map), do: row_map

  defp convert_row_to_map([h | t], index, row_map) do
    Map.update(row_map, index, h, fn _ -> h end)
    |> then(&convert_row_to_map(t, index + 1, &1))
  end
end
