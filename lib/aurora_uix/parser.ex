defmodule AuroraUix.Parser do
  @moduledoc """
  Processes the options and produces a map for further rendering.
  """

  alias AuroraUix.Parsers.Common
  alias AuroraUix.Parsers.ListParser

  @callback default_value(module :: module, key :: atom) :: any

  @doc """
  ## PARAMETERS
  * `module` (module): Schema module to be used for gathering field information.
  * `type` (atom): Type of view to generate.
  * `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
    See AuroraUixWeb.Uix.define/3 docs for type and opts details.
  """
  @spec parse(module, atom, Keyword.t()) :: map
  def parse(module, type, opts \\ []) do
    %{}
    |> Common.parse(module, type, opts)
    |> ListParser.parse(module, type, opts)
  end
end
