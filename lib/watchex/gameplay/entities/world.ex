defmodule Watchex.Gameplay.Entities.World do
  @moduledoc """
  A representation of world grid, players and gameplay

  - This process runs the gameplay of a particular world grid.
  - Registers and manages the player processes.
  - World is complete authoritative.
  """

  alias Watchex.CommonUtils.Records
  alias Watchex.Gameplay.Entities.Player
  alias Watchex.Gameplay.Utils.GridManager
  alias Watchex.Gameplay.Utils.Position

  use GenServer, restart: :transient
  require Logger

  @type t :: %Watchex.Gameplay.Entities.World{
          grid: map(),
          id: String.t(),
          players: map(),
          current_grid_id_index: number()
        }

  defstruct(grid: %{}, id: "", players: %{}, current_grid_id_index: 3)

  # Client functions

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Records.get_name(opts[:name]))
  end

  def create_player(world_id, player_id) do
    GenServer.call(Records.get_name(world_id), {"create_player", player_id})
  end

  def on_player_move(world_id, player_id, position, action) do
    GenServer.cast(Records.get_name(world_id), {"player_move", player_id, position, action})
  end

  def on_player_attack(world_id, player_id, position, action) do
    GenServer.cast(Records.get_name(world_id), {"player_attack", player_id, position, action})
  end

  def on_player_died(world_id, player_id) do
    GenServer.cast(Records.get_name(world_id), {"player_died", player_id})
  end

  def respawn_player(world_id, player_id) do
    GenServer.cast(Records.get_name(world_id), {"respawn", player_id})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    Logger.info("World created => #{inspect(opts[:info])}")
    {:ok, create_init_world_state(opts[:info])}
  end

  @impl true
  def handle_call({"create_player", player_id}, _from, state) do
    {status, world_state} = register_player(player_id, state)
    # IO.inspect(world_state)
    {:reply, status, world_state}
  end

  @impl true
  def handle_cast({"player_move", player_id, position, action}, state) do
    new_position = GridManager.move_on_grid(state.grid, position, action)
    Player.update_position(player_id, new_position)

    broadcast_to_all(state.id, "move_updated", %{
      id: player_id,
      position: new_position
    })

    {:noreply, state}
  end

  @impl true
  def handle_cast({"player_attack", player_id, position, _action}, state) do
    Enum.each(state.players, fn
      {enemy_player_id, _value} when enemy_player_id !== player_id ->
        Player.on_enemy_attack(enemy_player_id, position)

      _ ->
        :ok
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({"player_died", player_id}, state) do
    broadcast_to_all(state.id, "player_died", %{
      id: player_id
    })

    {:noreply, state}
  end

  @impl true
  def handle_cast({"respawn", player_id}, state) do
    handle_player_respawn(player_id, state)
    {:noreply, state}
  end

  # Utility functions

  @spec create_init_world_state(map()) :: Watchex.Gameplay.World.t()
  defp create_init_world_state(info) do
    __MODULE__.__struct__(
      grid: GridManager.get_world_grid(),
      id: info.id
    )
  end

  @spec register_player(String.t(), __MODULE__.t()) :: {:ok | :error, __MODULE__.t()}
  defp register_player(player_id, state) do
    init_position = GridManager.get_random_position(state.grid)

    {status, world_state} =
      spawn_player(init_position, player_id, state.id)
      |> update_world_state(init_position, player_id, state)

    broadcast_player_joined(status, state.id, player_id, init_position)
    {status, world_state}
  end

  @spec spawn_player(Position.t(), String.t(), String.t()) :: any()
  defp spawn_player(position, player_id, world_id) do
    status = Player.start(id: player_id, position: position, name: player_id, world_id: world_id)

    case status do
      {:ok, pid} ->
        Process.monitor(pid)
        :ok

      {:error, {:already_started}, _pid} ->
        Logger.info("Player already in world #{player_id}")
        :ok

      _ ->
        Logger.info("Error on creating player #{player_id}")
        :error
    end
  end

  @spec update_world_state(status :: atom(), Position.t(), String.t(), __MODULE__.t()) ::
          {atom(), __MODULE__.t()}
  defp update_world_state(:ok, position, player_id, state) do
    updated_players_data =
      Map.update(state.players, player_id, state.current_grid_id_index, fn _ ->
        state.current_grid_id_index
      end)

    updated_grid =
      state.grid
      |> update_world_grid(position, state.current_grid_id_index)

    {:ok,
     %{
       state
       | players: updated_players_data,
         current_grid_id_index: state.current_grid_id_index + 1,
         grid: updated_grid
     }}
  end

  defp update_world_state(_, _position, _player_id, state), do: {:error, state}

  @spec update_world_grid(map(), Position.t(), number()) :: map()
  defp update_world_grid(gridmap, position, value) do
    put_in(gridmap[position.row][position.col], value)
  end

  @spec broadcast_player_joined(spawn_status :: atom(), String.t(), String.t(), Position.t()) ::
          any()
  defp broadcast_player_joined(:ok, world_id, player_id, position) do
    broadcast_to_all(world_id, "player_joined", %{
      id: player_id,
      position: position
    })
  end

  defp broadcast_player_joined(_, _, _, _), do: :error

  @spec broadcast_to_all(String.t(), String.t(), map()) :: any()
  defp broadcast_to_all(world_id, event, data) do
    WatchexWeb.Endpoint.broadcast!("world:" <> world_id, event, data)
    :ok
  end

  @spec handle_player_respawn(String.t(), __MODULE__.t()) :: any()
  defp handle_player_respawn(player_id, state) do
    init_position = GridManager.get_random_position(state.grid)
    Player.on_respawned(player_id, init_position)

    broadcast_to_all(state.id, "player_respawned", %{
      id: player_id,
      position: init_position
    })
  end
end
