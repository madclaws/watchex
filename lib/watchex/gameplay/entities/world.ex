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
          id: String.t()
        }

  defstruct(grid: %{}, id: "")

  # Client functions

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Records.get_name(opts[:name]))
  end

  def create_player(world_id, player_id) do
    GenServer.call(Records.get_name(world_id), {"create_player", player_id})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    Logger.info("World created => #{inspect(opts[:info])}")
    {:ok, create_init_world_state(opts[:info])}
  end

  @impl true
  def handle_call({"create_player", player_id}, _from, state) do
    status = register_player(player_id, state)
    {:reply, status, state}
  end

  # Utility functions

  @spec create_init_world_state(map()) :: Watchex.Gameplay.World.t()
  defp create_init_world_state(info) do
    __MODULE__.__struct__(
      grid: GridManager.get_world_grid(),
      id: info.id
    )
  end

  @spec register_player(String.t(), __MODULE__.t()) :: pid()
  defp register_player(player_id, state) do
    init_position = GridManager.get_random_position(state.grid)

    spawn_player(init_position, player_id)
    |> broadcast_player_joined(state.id, player_id, init_position)
  end

  @spec spawn_player(Position.t(), String.t()) :: any()
  defp spawn_player(position, player_id) do
    status = Player.start(id: player_id, position: position, name: player_id)

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

  @spec broadcast_player_joined(spawn_status :: atom(), String.t(), String.t(), Position.t()) ::
          any()
  defp broadcast_player_joined(:ok, world_id, player_id, position) do
    WatchexWeb.Endpoint.broadcast!("world:" <> world_id, "player_joined", %{
      id: player_id,
      position: position
    })

    :ok
  end

  defp broadcast_player_joined(_, _, _, _), do: :error
end
