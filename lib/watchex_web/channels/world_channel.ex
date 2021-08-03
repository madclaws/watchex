defmodule WatchexWeb.WorldChannel do
  @moduledoc """
  Acts as communication interface between client and Game layer
  """

  alias Watchex.CommonUtils.Records
  alias Watchex.Gameplay.Entities.Player
  alias Watchex.Gameplay.Entities.World
  require Logger
  use Phoenix.Channel

  ## Callbacks

  @impl true
  def join("world:" <> world_id, params, socket) do
    if is_valid_player(params) do
      Process.send_after(self(), {"after_join", params, world_id}, 10)
      {:ok, socket}
    else
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
    Player.move(socket.assigns.user_id, action)
    {:noreply, socket}
  end

  @impl true
  def handle_in("player_attack", action, socket) do
    Player.attack(socket.assigns.user_id, action)
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    on_terminate(socket.assigns.user_id, socket)
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
        # Logger.info("World #{world_id} already created")
        :ok

      _error ->
        # Logger.info("Error creating World #{world_id} #{inspect(error)}")
        :error
    end
  end

  @spec create_player(status :: atom(), world_id :: String.t(), player_id :: String.t()) :: any()
  defp create_player(:ok, world_id, player_id) do
    World.create_player(world_id, player_id)
  end

  defp create_player(_, _, _), do: nil

  defp on_terminate(player_id, _socket) do
    case Records.is_process_registered(player_id) do
      [] ->
        # Logger.info("No process exists <#{inspect player_id}>")
        true

      _ ->
        Player.leave(player_id)
    end
  end
end
