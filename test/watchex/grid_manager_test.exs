defmodule Watchex.GridManagerTest do
  @moduledoc """
    All tests related to GridManager module
  """

  alias Watchex.Gameplay.Utils.GridManager

  use ExUnit.Case

  test "getWorldGrid decode success" do
    assert GridManager.get_world_grid() |> is_map()
  end

  test "get_random_position success" do
    gridmap = GridManager.get_world_grid()
    position = GridManager.get_random_position(gridmap)
    assert gridmap[position.row][position.col] !== 1
  end
end
