defmodule Watchex.Gameplay.Utils.Position do
  @moduledoc """
  Position struct and utitliy functions
  """

  @type t :: %Watchex.Gameplay.Utils.Position{
          row: number(),
          col: number()
        }

  @derive Jason.Encoder
  defstruct(
    row: 0,
    col: 0
  )

  @doc """
  Returns a new Position
  """
  @spec new(number(), number()) :: __MODULE__.t()
  def new(row, col) do
    __MODULE__.__struct__(
      row: row,
      col: col
    )
  end
end
