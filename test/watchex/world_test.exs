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
  test "world creation with correct world_id" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    world_state = :sys.get_state(pid)
    assert world_state.id === "demo"
  end

  test "player creation with correct player_id" do
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

  test "player move left" do
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

  @tag :skip
  test "player attack" do
    _pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    # world_state = :sys.get_state(pid)
    World.create_player("demo", "hero")
    World.create_player("demo", "enemy")
    World.create_player("demo", "enemy1")
    World.create_player("demo", "enemy2")

    hero_pid = Records.get_name("hero")
    hero_state = :sys.get_state(hero_pid)
    # IO.inspect(hero_state.position)
    # hero_position = hero_state.position
    # new_position = GridManager.move_on_grid(world_state.grid, hero_position, "Left")
    Player.attack("hero", "Attack")
    :timer.sleep(1_000)

    enemy_status_list =
      ["enemy", "enemy1", "enemy2"]
      |> Enum.map(fn enemy ->
        pid = Records.get_name(enemy)
        enemy_state = :sys.get_state(pid)
        {enemy_state.status, enemy_state.position}
      end)

    # IO.inspect(enemy_status_list)
  end

  @tag :skip
  test "player respawn" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    # world_state = :sys.get_state(pid)
    World.create_player("demo", "hero")

    hero_pid = Records.get_name("hero")
    hero_state = :sys.get_state(hero_pid)
    # IO.inspect(hero_state.position)
    hero_position = hero_state.position
    # new_position = GridManager.move_on_grid(world_state.grid, hero_position, "Left")
    Process.send_after(GenServer.whereis(hero_pid), "request_respawn", 10)
    :timer.sleep(1_000)
    hero_state = :sys.get_state(hero_pid)
    # IO.inspect(inspect hero_state.position)
  end
end
