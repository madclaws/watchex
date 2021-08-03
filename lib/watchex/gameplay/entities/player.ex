defmodule Watchex.Gameplay.Entities.Player do
  @moduledoc """
  Representing a player in the world.
  """

  alias Watchex.CommonUtils.Records
  alias Watchex.Gameplay.Entities.World
  alias Watchex.Gameplay.Utils.GridManager
  alias Watchex.Gameplay.Utils.Position
  use GenServer
  require Logger

  @type t :: %Watchex.Gameplay.Entities.Player{
          id: String.t(),
          position: Position.t(),
          status: :alive | :dead,
          world_id: String.t()
        }

  defstruct(
    id: "",
    position: %Position{row: 0, col: 0},
    status: :dead,
    world_id: ""
  )

  # Client functions

  @spec start(keyword()) :: any()
  def start(opts) do
    GenServer.start(__MODULE__, opts, name: Records.get_name(opts[:name]))
  end

  @spec move(String.t(), String.t()) :: any()
  def move(player_id, action) do
    GenServer.cast(Records.get_name(player_id), {"move", action})
  end

  @spec attack(String.t(), String.t()) :: any()
  def attack(player_id, action) do
    GenServer.cast(Records.get_name(player_id), {"attack", action})
  end

  @spec update_position(String.t(), Position.t()) :: any()
  def update_position(player_id, position) do
    GenServer.cast(Records.get_name(player_id), {"update_position", position})
  end

  @spec on_enemy_attack(String.t(), list(Position.t())) :: any()
  def on_enemy_attack(player_id, attack_position) do
    GenServer.cast(Records.get_name(player_id), {"enemy_attack", attack_position})
  end

  @spec on_respawned(String.t(), Position.t()) :: any()
  def on_respawned(player_id, new_position) do
    GenServer.cast(Records.get_name(player_id), {"on_respawned", new_position})
  end

  @spec get_position(String.t()) :: Position.t()
  def get_position(player_id) do
    GenServer.call(Records.get_name(player_id), "get_position")
  end

  @spec leave(String.t()) :: any()
  def leave(player_id) do
    GenServer.cast(Records.get_name(player_id), "leave")
  end

  # Server callbacks

  @impl true
  def init(opts) do
    {:ok, create_init_state(opts)}
  end

  @impl true
  def handle_cast({"move", action}, state) do
    World.on_player_move(state.world_id, state.id, state.position, action)
    {:noreply, state}
  end

  @impl true
  def handle_cast({"update_position", position}, state) do
    {:noreply, %{state | position: position}}
  end

  @impl true
  def handle_cast({"attack", action}, %__MODULE__{status: :alive} = state) do
    World.on_player_attack(state.world_id, state.id, state.position, action)
    {:noreply, state}
  end

  @impl true
  def handle_cast({"attack", _action}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({"enemy_attack", attack_position}, %__MODULE__{status: :alive} = state) do
    state = handle_enemy_attack(attack_position, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({"enemy_attack", _attack_position}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({"on_respawned", new_position}, state) do
    {:noreply,
     %__MODULE__{
       state
       | status: :alive,
         position: new_position
     }}
  end

  @impl true
  def handle_cast("leave", state) do
    World.on_player_left(state.world_id, state.id)
    {:noreply, state}
  end

  @impl true
  def handle_info("request_respawn", state) do
    World.respawn_player(state.world_id, state.id)
    {:noreply, state}
  end

  @impl true
  def handle_call("get_position", _from, state) do
    {:reply, state.position, state}
  end

  # Utility functions
  @spec create_init_state(keyword()) :: __MODULE__.t()
  defp create_init_state(opts) do
    __MODULE__.__struct__(
      id: opts[:id],
      position: opts[:position],
      status: :alive,
      world_id: opts[:world_id]
    )
  end

  @spec handle_enemy_attack(Position.t(), __MODULE__.t()) :: __MODULE__.t()
  defp handle_enemy_attack(attack_position, state) do
    GridManager.get_attackable_positions(attack_position)
    |> Enum.any?(fn attack_position ->
      attack_position.row === state.position.row and
        attack_position.col === state.position.col
    end)
    |> update_attack_status(state)
  end

  @spec update_attack_status(attack_status :: boolean(), __MODULE__.t()) :: __MODULE__.t()
  defp update_attack_status(true, state) do
    World.on_player_died(state.world_id, state.id)
    Process.send_after(self(), "request_respawn", 5_000)

    %__MODULE__{
      state
      | status: :died
    }
  end

  defp update_attack_status(_, state), do: state
end
