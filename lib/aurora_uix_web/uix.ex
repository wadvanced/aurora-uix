defmodule AuroraUixWeb.Uix do
  @moduledoc """
  Enable module for UIX functionality.
  """
  alias AuroraUixWeb.Template

  require Logger

  defmacro __using__(_opts) do
    quote do
      require unquote(Template.uix_template())
      import AuroraUixWeb.Uix.Renderer
    end
  end
end
