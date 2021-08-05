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
          player_pids: map(),
          current_grid_id_index: number()
        }

  defstruct(grid: %{}, id: "", players: %{}, player_pids: %{}, current_grid_id_index: 3)

  # Client functions

  @spec start_link(keyword()) :: any()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Records.get_name(opts[:name]))
  end

  @spec create_player(String.t(), String.t(), Position.t()) :: any()
  def create_player(world_id, player_id, position \\ nil)

  def create_player(world_id, player_id, position) do
    GenServer.call(Records.get_name(world_id), {"create_player", player_id, position})
  end

  @spec on_player_move(String.t(), String.t(), Position.t(), String.t()) :: any()
  def on_player_move(world_id, player_id, position, action) do
    GenServer.cast(Records.get_name(world_id), {"player_move", player_id, position, action})
  end

  @spec on_player_attack(String.t(), String.t(), Position.t(), String.t()) :: any()
  def on_player_attack(world_id, player_id, position, action) do
    GenServer.cast(Records.get_name(world_id), {"player_attack", player_id, position, action})
  end

  @spec on_player_died(String.t(), String.t()) :: any()
  def on_player_died(world_id, player_id) do
    GenServer.cast(Records.get_name(world_id), {"player_died", player_id})
  end

  @spec respawn_player(String.t(), String.t()) :: any()
  def respawn_player(world_id, player_id) do
    GenServer.cast(Records.get_name(world_id), {"respawn", player_id})
  end

  @spec on_player_left(String.t(), String.t()) :: any()
  def on_player_left(world_id, player_id) do
    GenServer.cast(Records.get_name(world_id), {"player_left", player_id})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, create_init_world_state(opts[:info])}
  end

  @impl true
  def handle_call({"create_player", player_id, position}, _from, state) do
    {status, world_state} = register_player(player_id, state, position)
    {:reply, status, world_state}
  end

  @impl true
  def handle_cast({"player_move", player_id, position, action}, state) do
    new_position = GridManager.move_on_grid(state.grid, position, action)
    pid = state.players[player_id]

    player_pid_data =
      Map.update(state.player_pids, pid, {new_position, player_id}, fn _ ->
        {new_position, player_id}
      end)

    Player.update_position(player_id, new_position)

    broadcast_to_all(state.id, "move_updated", %{
      id: player_id,
      position: new_position
    })

    {:noreply, %{state | player_pids: player_pid_data}}
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

  @impl true
  def handle_cast({"player_left", player_id}, state) do
    state =
      Map.delete(state.players, player_id)
      |> then(&Map.update!(state, :players, fn _ -> &1 end))

    player_pid = GenServer.whereis(Records.get_name(player_id))
    {position, _player_id} = state.player_pids[player_pid]

    Process.exit(GenServer.whereis(Records.get_name(player_id)), :left)

    broadcast_to_all(state.id, "player_left", %{
      id: player_id,
      position: position
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, state) do
    state = handle_player_crash(reason, pid, state)

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

  @spec register_player(String.t(), __MODULE__.t(), Position.t()) ::
          {:ok | :error, __MODULE__.t()}

  defp register_player(player_id, state, position) do
    init_position = get_new_position(position, state.grid)

    {status, world_state} =
      spawn_player(init_position, player_id, state.id)
      |> update_world_state(init_position, player_id, state)

    broadcast_player_joined(status, world_state)
    {status, world_state}
  end

  @spec spawn_player(Position.t(), String.t(), String.t()) :: any()
  defp spawn_player(position, player_id, world_id) do
    status =
      Player.start_link(id: player_id, position: position, name: player_id, world_id: world_id)

    case status do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      _error ->
        :error
    end
  end

  @spec update_world_state(
          {status :: atom(), pid: pid()},
          Position.t(),
          String.t(),
          __MODULE__.t()
        ) ::
          {atom(), __MODULE__.t()}
  defp update_world_state({:ok, pid}, position, player_id, state) do
    updated_players_data =
      Map.update(state.players, player_id, pid, fn _ ->
        pid
      end)

    player_pids =
      Map.update(state.player_pids, pid, {position, player_id}, fn _ -> {position, player_id} end)

    updated_grid =
      state.grid
      |> update_world_grid(position, state.current_grid_id_index)

    {:ok,
     %{
       state
       | players: updated_players_data,
         player_pids: player_pids,
         current_grid_id_index: state.current_grid_id_index + 1,
         grid: updated_grid
     }}
  end

  defp update_world_state(_, _position, _player_id, state), do: {:error, state}

  @spec update_world_grid(map(), Position.t(), number()) :: map()
  defp update_world_grid(gridmap, position, value) do
    put_in(gridmap[position.row][position.col], value)
  end

  @spec broadcast_player_joined(spawn_status :: atom(), __MODULE__.t()) ::
          any()
  defp broadcast_player_joined(:ok, state) do
    players_in_world =
      state.players
      |> Enum.map(fn {player_id, _value} ->
        %{id: player_id, position: Player.get_position(player_id)}
      end)

    broadcast_to_all(state.id, "player_joined", %{players: players_in_world})
  end

  defp broadcast_player_joined(_, _), do: :error

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

  # We need to restart the player to its old position, if it crashes unusually
  @spec handle_player_crash(reason :: atom(), pid(), __MODULE__.t()) :: __MODULE__.t()
  defp handle_player_crash(:left, pid, state) do
    Map.delete(state.player_pids, pid)
    |> then(&Map.update!(state, :player_pids, fn _ -> &1 end))
  end

  defp handle_player_crash(_reason, pid, state) do
    {position, player_id} = state.player_pids[pid]

    {_status, world_state} =
      Map.delete(state.player_pids, pid)
      |> then(&Map.update!(state, :player_pids, fn _ -> &1 end))
      |> then(&register_player(player_id, &1, position))

    world_state
  end

  @spec get_new_position(position :: Position.t(), gridmap :: map()) :: Position.t()
  defp get_new_position(nil, gridmap) do
    GridManager.get_random_position(gridmap)
  end

  defp get_new_position(position, _gridmap), do: position
end
