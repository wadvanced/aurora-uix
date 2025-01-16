defmodule AuroraUix.Parser do
  @moduledoc """
  Processes the options and produces a map for further rendering.
  """

  alias AuroraUix.Parsers.Common
  alias AuroraUix.Parsers.IndexParser

  @callback default_value(module :: module, key :: atom) :: any

  @doc """
  ## Parameters
    - `module` (module): Schema module to be used for gathering field information.
    - `type` (atom): Type of view to generate.
    - `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
    See AuroraUixWeb.Uix.define/3 docs for type and opts details.

  ## Parsed output
    A map with the following content is produced

  ### Common keys
   - `:module`: Last part of the name of the schema module. For schema `AuroraUixDemo.GeneralLedger.Account` then %{module: "account"}.
   - `:name`: Capitalize schema module. For schema `AuroraUixDemo.GeneralLedger.Account` then %{name: "Account"}
   - `:source`: The table name of the schema. For example: %{source: "account receivable"}
   - `:title`: The pluralize name of the module. For schema `AuroraUixDemo.GeneralLedger.AccountReceivable` then %{title: "Account receivables"}.
   - `:fields`: List of the schema fields

  ### Index keys
   - `:rows`: Keys path for accessing the socket list of elements. For schema `AuroraUixDemo.GeneralLedger.AccountReceivable`
    the %{rows: [:streams, :account_receivables]

  """
  @spec parse(module, atom, Keyword.t()) :: map
  def parse(module, type, opts \\ []) do
    %{}
    |> Common.parse(module, type, opts)
    |> IndexParser.parse(module, type, opts)
  end
end
