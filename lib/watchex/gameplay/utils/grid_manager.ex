defmodule Watchex.Gameplay.Utils.GridManager do
  @moduledoc """
  Contains core functions for handling the world grid
  """

  @grid_width 10
  @grid_height 10

  @empty_cell 0
  @wall_cell 1
  @walkable_cell 2
  @player_cell 3
  @enemy_cell 4

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
