defmodule AuroraUixWeb.Uix do
  @moduledoc """
  Enable module for UIX functionality.
  """

  require Logger

  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.Renderer
    end
  end
end
