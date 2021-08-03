defmodule WatchexWeb.WorldChannel do
  @moduledoc """
  Acts as communication interface between client and Game layer
  """

  alias Watchex.Gameplay.Entities.Player
  alias Watchex.Gameplay.Entities.World
  require Logger
  use Phoenix.Channel

  ## Callbacks

  @impl true
  def join("world:" <> world_id, params, socket) do
    if is_valid_player(params) do
      Logger.metadata(world_id: world_id)
      Logger.info("Player joined => #{socket.assigns[:user_id]}")
      Process.send_after(self(), {"after_join", params, world_id}, 10)
      {:ok, socket}
    else
      Logger.info("Invalid player => #{socket.assigns[:user_id]} => #{world_id}")
      {:error, %{reason: "Player is invalid"}}
    end
  end

  @impl true
  def handle_info({"after_join", %{"userId" => player_id} = _params, world_id}, socket) do
    create_world(world_id)
    |> create_player(world_id, player_id)

    {:noreply, socket}
  end

  @impl true
  def handle_in("player_move", action, socket) do
    Logger.info("Player move #{socket.assigns.user_id} => #{inspect(action)}")
    Player.move(socket.assigns.user_id, action)
    {:noreply, socket}
  end

  ## Utility functions

  @spec is_valid_player(params :: map()) :: boolean()
  defp is_valid_player(_params) do
    # Validate player here
    true
  end

  @spec create_world(String.t()) :: :ok | :error
  defp create_world(world_id) do
    status =
      DynamicSupervisor.start_child(
        Watchex.WorldSupervisor,
        {World, name: world_id, info: %{id: world_id}}
      )

    case status do
      {:ok, _child} ->
        :ok

      {:error, {:already_started, _child}} ->
        Logger.info("World #{world_id} already created")
        :ok

      error ->
        Logger.info("Error creating World #{world_id} #{inspect(error)}")
        :error
    end
  end

  @spec create_player(status :: atom(), world_id :: String.t(), player_id :: String.t()) :: any()
  defp create_player(:ok, world_id, player_id) do
    World.create_player(world_id, player_id)
  end

  defp create_player(_, _, _), do: nil
end
