defmodule Watchex.Gameplay.Entities.Player do
  @moduledoc """
  Representing a player in the world.
  """

  alias Watchex.CommonUtils.Records
  alias Watchex.Gameplay.Entities.World
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
  def start(opts) do
    GenServer.start(__MODULE__, opts, name: Records.get_name(opts[:name]))
  end

  def move(player_id, action) do
    GenServer.cast(Records.get_name(player_id), {"move", action})
  end

  @spec update_position(String.t(), Position.t()) :: any()
  def update_position(player_id, position) do
    GenServer.cast(Records.get_name(player_id), {"update_position", position})
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

  # Utility functions

  @spec create_init_state(keyword()) :: __MODULE__.t()
  defp create_init_state(opts) do
    Logger.info("Player created => #{opts[:id]} at #{inspect(opts[:position])}")

    __MODULE__.__struct__(
      id: opts[:id],
      position: opts[:position],
      status: :alive,
      world_id: opts[:world_id]
    )
  end
end
