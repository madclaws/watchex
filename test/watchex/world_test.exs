defmodule Watchex.WorldTest do
  @moduledoc """
    All tests related to GridManager module
  """

  alias Watchex.CommonUtils.Records
  alias Watchex.Gameplay.Entities.Player
  alias Watchex.Gameplay.Entities.World
  alias Watchex.Gameplay.Utils.GridManager
  use ExUnit.Case

  # @tag :skip
  test "test world creation with correct world_id" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    world_state = :sys.get_state(pid)
    assert world_state.id === "demo"
  end

  test "test player creation with correct player_id" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    world_state = :sys.get_state(pid)
    World.create_player("demo", "hero")
    hero_pid = Records.get_name("hero")
    hero_state = :sys.get_state(hero_pid)
    # IO.inspect(hero_state)
    # IO.puts("\n")
    # IO.inspect(world_state)
    assert hero_state.id === "hero"
  end

  test "test player move left" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    world_state = :sys.get_state(pid)
    World.create_player("demo", "hero")
    hero_pid = Records.get_name("hero")
    hero_state = :sys.get_state(hero_pid)
    # IO.inspect(hero_state.position)
    hero_position = hero_state.position
    new_position = GridManager.move_on_grid(world_state.grid, hero_position, "Left")
    Player.move("hero", "Left")
    :timer.sleep(1_000)
    hero_state = :sys.get_state(hero_pid)
    hero_position2 = hero_state.position
    # IO.inspect(hero_state.position)
    assert hero_position2.col === new_position.col and hero_position2.row === new_position.row
  end
end
