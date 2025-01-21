defmodule AuroraUixWeb.Uix.SchemaMetadata do
  @moduledoc """
  Provides schema metadata management for AuroraUixWeb.

  This module is responsible for attaching and managing UI-related metadata for Ecto schemas.
  This metadata enhances schema usability in UI rendering, enabling customization of fields, placeholders, labels, and other attributes.

  The primary functions include:

  - `__uix_metadata__/4`: Registers schema metadata, including fields and their configurations.
  - `field/2`: Adds or updates field-specific metadata.
  - Internal utilities for deriving field attributes such as labels, placeholders, and types based on schema definitions.

  ## Example

  ```elixir
    defmodule MyApp.Product do
      use Ecto.Schema
      import Ecto.Changeset

      schema "products" do
        field :name, :string
        field :price, :float
        field :quantity, :integer
        belongs_to :category, MyApp.Category

        timestamps()
      end
    end

    defmodule MyApp.Category do
      use Ecto.Schema
      import Ecto.Changeset

      schema "categories" do
        field :name, :string
        has_many :products, MyApp.Product

        timestamps()
      end
    end

    defmodule MyAppWeb.ProductLive.Index do
      uix_schema_metadata :product, MyApp.Product, MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end

      uix_schema_metadata :category, MyApp.Category do
        field :id, readonly: true
        field :name, max_length: 20, required: true
      end
  ```
  """

  alias AuroraUix.Field
  alias AuroraUixWeb.Uix.SchemaMetadata

  @doc """
  Adds or updates metadata for a specific field in the schema.

  This macro allows customization of individual fields, such as setting labels, placeholders, types, and validation rules.
  The updates are stored in the schema metadata registered in the current module.

  ## Parameters

  - `field` (`atom`) - The name of the schema field.
  - `opts` (`Keyword.t`) - A keyword list of field options.

  ## Options

  The following options can be provided to configure the field:

            field: atom | nil,
          html_type: atom | nil,
          renderer: function | nil,
          name: binary,
          label: binary,
          placeholder: binary,
          length: non_neg_integer,
          precision: non_neg_integer,
          scale: non_neg_integer,
          hidden: boolean,
          readonly: boolean


  - `:field` (`atom`) - The referred field in the schema. This should be rarely changed.
  - `:html_type`(`atom`) - The html type that best represent the current field elixir type.
  - `:label` (`binary`) - A custom label for the field.
  - `:placeholder` (`binary`) - Placeholder text for the field.
  - `:precision` (`integer`) - The numeric precision for decimal or float fields.
  - `:readonly` (`boolean`) - Marks the field as read-only.
  - `:renderer` (`function`) - A function that can render the field. It can refer a function component.
  - `:required` (`boolean`) - Marks the field as required.
  - `:scale` (`integer`) - The numeric scale for decimal or float fields.

  ## Example

  ```elixir
  field :name, label: "Product Name", placeholder: "Enter product name", required: true
  field :price, precision: 12, scale: 2, label: "Price ($)"
  """
  @spec field(atom, Keyword.t()) :: Macro.t()
  defmacro field(field, opts \\ []) do
    quote do
      SchemaMetadata.__field__(
        __MODULE__,
        unquote(field),
        Macro.escape(unquote(opts))
      )
    end
  end

  @doc """
  Registers schema metadata for a given schema within the module.

  This function attaches metadata such as schema fields, context, and other configurations. It is typically used internally by the `uix_schema_metadata` macro.

  ## Parameters

  - `module` (`module`) - The module where metadata is being registered.
  - `name` (`atom`)- An identifier for the schema metadata (atom).
  - `schema` (`module`) - The Ecto schema module.
  - `context` (`module`) - The associated context module. This module should have the functions for operating on
    the schema module. Can be omitted if the operations are performed using another approach.
  """
  @spec __uix_metadata__(module, atom, module, module) :: :ok
  def __uix_metadata__(module, name, schema, context) do
    module
    |> Module.get_attribute(:auix_schemas, %{})
    |> Map.put(name, %{schema: schema, context: context, fields: fields(schema)})
    |> then(&Module.put_attribute(module, :auix_schemas, &1))
    |> tap(fn _ -> Module.put_attribute(module, :auix_current_schema_name, name) end)
  end

  @spec __field__(module, atom, Keyword.t()) :: :ok
  def __field__(module, field, opts) do
    name = Module.get_attribute(module, :auix_current_schema_name)

    changed_field =
      module
      |> Module.get_attribute(:auix_schemas, %{})
      |> get_in([name, :fields, field])
      |> Kernel.||(Field.new())
      |> Field.change(opts)

    module
    |> Module.get_attribute(:auix_schemas, %{})
    |> put_in([name, :fields, field], changed_field)
    |> then(&Module.put_attribute(module, :auix_schemas, &1))
  end

  ## PRIVATE
  @spec fields(module) :: map
  defp fields(schema) do
    Code.ensure_compiled(schema)

    if function_exported?(schema, :__schema__, 1) do
      :fields
      |> schema.__schema__()
      |> Enum.map(&fields_field(schema, &1))
      |> Map.new()
    else
      %{}
    end
  end

  @spec fields_field(module, atom | binary) :: {atom | binary, Field.t()}
  defp fields_field(module, field) do
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

    {field, Field.new(attrs)}
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
