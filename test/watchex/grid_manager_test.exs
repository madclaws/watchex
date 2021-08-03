defmodule Watchex.GridManagerTest do
  @moduledoc """
    All tests related to GridManager module
  """

  alias Watchex.Gameplay.Utils.GridManager
  alias Watchex.Gameplay.Utils.Position
  use ExUnit.Case

  test "test getWorldGrid decode success" do
    assert GridManager.get_world_grid() |> is_map()
  end

  test "test get_random_position success" do
    gridmap = GridManager.get_world_grid()
    position = GridManager.get_random_position(gridmap)
    assert gridmap[position.row][position.col] !== 1
  end

  test "test move_on_grid (Left)" do
    gridmap = GridManager.get_world_grid()
    position = Position.new(1, 2)
    new_position = GridManager.move_on_grid(gridmap, position, "Left")
    assert new_position.col === position.col - 1 and new_position.row === position.row
  end

  test "test move_on_grid (Right)" do
    gridmap = GridManager.get_world_grid()
    position = Position.new(1, 2)
    new_position = GridManager.move_on_grid(gridmap, position, "Right")
    assert new_position.col === position.col + 1 and new_position.row === position.row
  end

  test "test move_on_grid (Up)" do
    gridmap = GridManager.get_world_grid()
    position = Position.new(2, 2)
    new_position = GridManager.move_on_grid(gridmap, position, "Up")
    assert new_position.col === position.col and new_position.row === position.row - 1
  end

  test "test move_on_grid (Down)" do
    gridmap = GridManager.get_world_grid()
    position = Position.new(2, 2)
    new_position = GridManager.move_on_grid(gridmap, position, "Down")
    assert new_position.col === position.col and new_position.row === position.row + 1
  end

  test "test move_on_grid (moving to walls Up)" do
    gridmap = GridManager.get_world_grid()
    position = Position.new(1, 2)
    new_position = GridManager.move_on_grid(gridmap, position, "Up")
    assert new_position.col === position.col and new_position.row === position.row
  end

  test "test move_on_grid (moving from  walls to outside)" do
    gridmap = GridManager.get_world_grid()
    position = Position.new(0, 0)
    new_position = GridManager.move_on_grid(gridmap, position, "Left")
    assert new_position.col === position.col and new_position.row === position.row
  end

  test "test get_attackable_positions" do
    attack_position = Position.new(5, 6)
    attack_position_list = GridManager.get_attackable_positions(attack_position)
    # IO.inspect(attack_position_list)
    assert length(attack_position_list) === 9
  end
end
