defmodule Watchex.Gameplay.Entities.Player do
  @moduledoc """
  Representing a player in the world.
  """

  alias Watchex.CommonUtils.Records
  alias Watchex.Gameplay.Utils.Position
  use GenServer
  require Logger

  @type t :: %Watchex.Gameplay.Entities.Player{
          id: String.t(),
          position: Position.t(),
          status: :alive | :dead
        }

  defstruct(
    id: "",
    position: %Position{row: 0, col: 0},
    status: :dead
  )

  # Client functions
  def start(opts) do
    GenServer.start(__MODULE__, opts, name: Records.get_name(opts[:name]))
  end

  # Server callbacks
  @impl true
  def init(opts) do
    {:ok, create_init_state(opts)}
  end

  # Utility functions

  @spec create_init_state(keyword()) :: __MODULE__.t()
  defp create_init_state(opts) do
    Logger.info("Player created => #{opts[:id]} at #{inspect(opts[:position])}")

    __MODULE__.__struct__(
      id: opts[:id],
      position: opts[:position],
      status: :alive
    )
  end
end
