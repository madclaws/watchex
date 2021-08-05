defmodule Watchex.WorldTest do
  @moduledoc """
    All tests related to GridManager module
  """

  alias Watchex.CommonUtils.Records
  alias Watchex.Gameplay.Entities.Player
  alias Watchex.Gameplay.Entities.World
  alias Watchex.Gameplay.Utils.GridManager
  alias Watchex.Gameplay.Utils.Position
  use ExUnit.Case

  test "world creation with correct world_id" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    world_state = :sys.get_state(pid)
    assert world_state.id === "demo"
  end

  test "player creation with correct player_id" do
    _pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    World.create_player("demo", "hero")
    hero_pid = Records.get_name("hero")
    hero_state = :sys.get_state(hero_pid)
    assert hero_state.id === "hero"
  end

  test "player creation with specified position" do
    _pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    World.create_player("demo", "hero", Position.new(1, 2))
    hero_pid = Records.get_name("hero")
    hero_state = :sys.get_state(hero_pid)
    assert hero_state.position === Position.new(1, 2)
  end

  test "player move left" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    world_state = :sys.get_state(pid)
    World.create_player("demo", "hero")
    hero_pid = Records.get_name("hero")
    hero_state = :sys.get_state(hero_pid)
    hero_position = hero_state.position
    new_position = GridManager.move_on_grid(world_state.grid, hero_position, "Left")
    Player.move("hero", "Left")
    :timer.sleep(1_000)
    hero_state = :sys.get_state(hero_pid)
    hero_position2 = hero_state.position
    assert hero_position2 === new_position
  end

  test "player move right" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    _world_state = :sys.get_state(pid)
    World.create_player("demo", "hero", Position.new(2, 5))
    Player.move("hero", "Right")
    :timer.sleep(1_000)
    hero_pid = Records.get_name("hero")
    hero_state = :sys.get_state(hero_pid)
    hero_position2 = hero_state.position
    assert hero_position2 === Position.new(2, 6)
  end

  test "player attack" do
    _pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    World.create_player("demo", "hero", Position.new(2, 5))
    World.create_player("demo", "enemy", Position.new(2, 6))
    World.create_player("demo", "enemy1", Position.new(1, 2))
    World.create_player("demo", "enemy2", Position.new(6, 6))

    _hero_pid = Records.get_name("hero")
    Player.attack("hero", "Attack")
    :timer.sleep(1_000)

    pid = Records.get_name("enemy")
    enemy_state = :sys.get_state(pid)
    assert enemy_state.status === :died
  end

  test "player respawn after 5 seconds" do
    _pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    World.create_player("demo", "hero", Position.new(2, 5))
    World.create_player("demo", "enemy", Position.new(2, 6))

    Player.attack("hero", "Attack")
    :timer.sleep(1_000)
    pid = Records.get_name("enemy")
    enemy_state = :sys.get_state(pid)
    enemy_on_attack_status = enemy_state.status
    :timer.sleep(6_000)
    enemy_state = :sys.get_state(pid)
    enemy_on_respawn_status = enemy_state.status
    assert {enemy_on_attack_status, enemy_on_respawn_status} === {:died, :alive}
  end

  test "player should not respawn before 5 seconds" do
    _pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    World.create_player("demo", "hero", Position.new(2, 5))
    World.create_player("demo", "enemy", Position.new(2, 6))

    Player.attack("hero", "Attack")
    :timer.sleep(1_000)
    pid = Records.get_name("enemy")
    enemy_state = :sys.get_state(pid)
    enemy_on_attack_status = enemy_state.status
    :timer.sleep(3_000)
    enemy_state = :sys.get_state(pid)
    enemy_on_respawn_status = enemy_state.status
    refute {enemy_on_attack_status, enemy_on_respawn_status} === {:died, :alive}
  end

  test "Player supervision by world: handle crashes" do
    pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    World.create_player("demo", "hero", Position.new(2, 5))

    player_pid = GenServer.whereis(Records.get_name("hero"))
    _player_state = :sys.get_state(pid)
    Process.exit(player_pid, :crash)
    :timer.sleep(1000)
    assert is_pid(GenServer.whereis(Records.get_name("hero")))
  end

  test "Player supervision by world: restarts player with last know position" do
    _pid = start_supervised!({World, name: "demo", info: %{id: "demo"}})
    World.create_player("demo", "hero", Position.new(2, 5))
    Player.move("hero", "Left")
    :timer.sleep(1000)
    player_pid = GenServer.whereis(Records.get_name("hero"))
    Process.exit(player_pid, :crash)
    :timer.sleep(1000)
    player_pid = GenServer.whereis(Records.get_name("hero"))
    player_state = :sys.get_state(player_pid)
    assert player_state.position === Position.new(2, 4)
  end
end
