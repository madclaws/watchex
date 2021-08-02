defmodule Watchex.CommonUtils.Records do
  @moduledoc """
  Abstracts Elixir's Registry for reuse and readability
  """

  @doc """
    Registering and accessing named process.
    Accepts `process_name`
  """
  def get_name(process_name) do
    {:via, Registry, {Watchex.GameRegistry, process_name}}
  end

  @doc """
    Returns if a process is still in Registry
    Accepts `process_name`
  """
  def is_process_registered(process_name) do
    Registry.lookup(Watchex.GameRegistry, process_name)
  end
end
