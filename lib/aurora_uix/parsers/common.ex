defmodule AuroraUix.Parsers.Common do
  @moduledoc """
  Parse common options and adds the module related values.
  """

  use AuroraUix.Parsers.BaseParser

  alias AuroraUix.Field

  @doc """
  Parse module and common options.

  ## PARAMETERS
  * `module` (module): Schema module to be used for gathering field information.
  * `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
    ### Common opts
    * `actions: [{:top | :bottom, function}]` : Overrides the default list of actions that are displayed at the top or bottom.
    * `add_opt: []`: List of fields to be added to the default list, duplicated fields are ignored.
      A proper warning message will be issued.
    * `add_actions: [{:top | :bottom, function}]`: Adds actions to the current list.
    * `fields: []`: Fields to be used, overrides the default list.
      The default list is created with all the fields found in the module, excluding
      the redacted fields.
    * `name: :string`: Name of the schema. By default, uses the last part of the module name.
    * `remove: []`: List of fields to be remove from the list.
      trying to remove non-existing fields will log a warning, but no error will be raised.
    * `remove_actions: [function]`: Removes actions from the current list.
    * `source` : Key of the data. By default, resolves the source from the schema source value.
      Uses the function __schema__/1 passing :source as the argument.
    * `sub_title: string | :hide`: Subtitle for the view, a :hide value will disallow its generation.
    * `template: Module`: Overrides the module that handles the generation.
      By default, uses AuroraUixWeb.AuroraTemplate, which is a sophisticated and highly opinionated template.
      There is also the AuroraUixWeb.PhoenixTemplate, which resembles the phoenix ui.
      The template can also be configured, application wide, by adding :aurora_uix, template: Module.
      New templates can be authored.
    * `title: string`: Title for the UI. Uses the capitalized schema source as the title.
      #### Example
      Schema module: GeneralLedger.Account
      Schema source: "accounts"
      Title: "Accounts"

      #### Example
      Schema module: GeneralLedger.AccountReceivable
      Schema source: "account_receivables"
      Title: "Account receivables"

  ## Example
    iex> alias AuroraUix.Parsers.Common
    iex> defmodule AuroraUix.GeneralLedger.Account do
    ...>    use Ecto.Schema
    ...>    schema "accounts" do
    ...>      field :description, :string
    ...>      field :number, :string
    ...>      timestamps()
    ...>    end
    ...>  end
    iex> parsed = Common.parse(%{}, AuroraUix.GeneralLedger.Account, [])
    iex> parsed.name == "Account" # Name is taken from last part of the schema module name
    true
    iex> parsed.title == "Accounts" # Uses the capitalized schema source as the title.

    iex> alias AuroraUix.Parsers.Common
    iex> defmodule AuroraUix.GeneralLedger.AccountReceivable do
    ...>   use Ecto.Schema
    ...>   schema "account_receivables" do
    ...>     field :description, :string
    ...>     field :amount, :float
    ...>     timestamps()
    ...>   end
    ...> end
    iex> parsed = Common.parse(%{}, AuroraUix.GeneralLedger.AccountReceivable, [])
    iex> parsed.title == "Account Receivables"  # Uses the capitalized schema source as the title
  """
  @spec parse(map, module, Keyword.t()) :: map
  def parse(parsed_opts, module, opts) do
    parsed_opts
    |> add_opt(module, opts, :module)
    |> add_opt(module, opts, :name)
    |> add_opt(module, opts, :source)
    |> add_opt(module, opts, :title)
    |> add_opt(module, opts, :fields)
  end

  @doc """
  Resolves the default value.

  ### Parameters
  * `module (module)`: Schema module.
  * `key (atom)`: Key value to produce the value from.

  """
  @spec default_value(module, atom) :: any

  def default_value(module, :module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  def default_value(module, :name) do
    module
    |> Module.split()
    |> List.last()
    |> capitalize()
  end

  def default_value(module, :source), do: module.__schema__(:source)

  def default_value(module, :title) do
    :source
    |> module.__schema__()
    |> capitalize()
  end

  def default_value(module, :fields) do
    :fields
    |> module.__schema__()
    |> Enum.reject(&(&1 in [:id, :inserted_at, :updated_at]))
    |> Enum.map(&field(module, &1))
  end

  ## PRIVATE

  @spec field(module, atom | binary) :: Field.t()
  defp field(module, field) do
    type = module.__schema__(:type, field)

    attrs = %{
      field: field,
      label: field_label(field),
      placeholder: field_placeholder(field, type),
      html_type: field_html_type(type),
      length: field_length(type),
      precision: field_precision(type),
      scale: field_scale(type)
    }

    Field.new(attrs)
  end

  @spec field_label(binary) :: binary
  defp field_label(nil), do: ""

  defp field_label(name),
    do: name |> to_string() |> String.capitalize() |> String.replace("_", " ")

  @spec field_placeholder(binary, atom) :: binary
  defp field_placeholder(_, type) when type in [:id, :integer, :float, :decimal], do: "0"

  defp field_placeholder(_, type)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: "yyyy/MM/dd HH:mm:ss"

  defp field_placeholder(_, type) when type in [:time, :time_usec], do: "HH:mm:ss"
  defp field_placeholder(name, _type), do: name |> to_string() |> String.capitalize()

  @spec field_html_type(atom) :: atom
  defp field_html_type(type) when type in [:string, :binary_id, :binary, :bitstring, Ecto.UUID],
    do: :text

  defp field_html_type(type) when type in [:id, :integer, :float, :decimal], do: :number

  defp field_html_type(type)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: :datetime_local

  defp field_html_type(type) when type in [:time, :time_usec], do: :time
  defp field_html_type(type), do: type

  @spec field_length(atom) :: integer
  defp field_length(type) when type in [:string, :binary_id, :binary, :bitstring], do: 255
  defp field_length(type) when type in [:id, :integer], do: 10
  defp field_length(type) when type in [:float, :decimal], do: 12

  defp field_length(type)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: 20

  defp field_length(type) when type in [:time, :time_usec], do: 10
  defp field_length(Ecto.UUID), do: 34
  defp field_length(_type), do: 50

  @spec field_precision(atom) :: integer
  defp field_precision(type) when type in [:id, :integer, :float, :decimal], do: 10
  defp field_precision(_type), do: 0

  @spec field_precision(atom) :: integer
  defp field_scale(type) when type in [:float, :decimal], do: 2
  defp field_scale(_type), do: 0
end
