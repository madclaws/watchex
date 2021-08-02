defmodule Watchex.WorldTest do
  @moduledoc """
    All tests related to GridManager module
  """

  alias Watchex.CommonUtils.Records
  alias Watchex.Gameplay.Entities.Player
  alias Watchex.Gameplay.Entities.World
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
    assert hero_state.id === "hero"
  end
end
