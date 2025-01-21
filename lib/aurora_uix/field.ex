defmodule AuroraUix.Field do
  @moduledoc """
  A module representing a configurable field in the AuroraUix system.

  This module defines a struct to represent field properties for UI components, such as:
    - `field` (`atom`) - The field reference in the schema.
    - `name` (`binary`) - The field's name as a binary.
    - `html_type` (`atom`) - The HTML type of the field (e.g., `:text`, `:number`, `:date`).
    - `renderer` (`function`) - A custom rendering function for the field.
    - `label` (`binary`) - A display label for the field.
    - `placeholder` (`binary`) - Placeholder text for input fields.
    - `length` (`non_neg_integer`) - Maximum allowed length of input (used for validations).
    - `precision` (`non_neg_integer`) - Number of digits for numeric fields.
    - `scale` (`non_neg_integer`) - Number of digits to the right of the decimal separator, for numeric fields.
    - `hidden` (`boolean`) - If true the field should be included, but not visible.
      However, it is up to the implementation whether to include the field in the generated artifact or not.
    - `readonly` (`boolean`) - If true the field should not accept changes.
    - `required` (`boolean`) - Indicates that the field should not be empty or unused.

  """
  defstruct [
    :field,
    :html_type,
    :renderer,
    name: "",
    label: "",
    placeholder: "",
    length: 0,
    precision: 0,
    scale: 0,
    hidden: false,
    readonly: false,
    required: false
  ]

  @type t() :: %__MODULE__{
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
          readonly: boolean,
          required: boolean
        }

  @doc """
  Creates a new `%AuroraUix.Field{}` struct with the given attributes.

    ## Parameters

    - `attrs` (map | keyword list): A map or keyword list of attributes to initialize the struct.
      Keys not present in the struct are ignored. Default is an empty map.

  ## Examples

      iex> AuroraUix.Field.new(%{field: :age, html_type: :float, precision: 10, scale: 2})
      %AuroraUix.Field{
        field: :age,
        html_type: :float,
        renderer: nil,
        name: :age,
        label: "",
        placeholder: "",
        length: 0,
        precision: 10,
        scale: 2,
        hidden: false,
        readonly: false,
        required: false
      }


      iex> AuroraUix.Field.new([field: :username, html_type: :text])
      %AuroraUix.Field{
        field: :username,
        html_type: :text,
        renderer: nil,
        name: :username,
        label: "",
        placeholder: "",
        length: 0,
        precision: 0,
        scale: 0,
        hidden: false,
        readonly: false,
        required: false
      }
  """
  @spec new(map | keyword) :: __MODULE__.t()
  def new(attrs \\ %{}), do: change(%__MODULE__{}, attrs)

  @doc """
  Updates an existing `%AuroraUix.Field{}` struct with new attributes.

    ## Parameters

      - `field` (t()): The existing field struct.
      - `attrs` (map | keyword list): A map or keyword list of attributes to update the struct.
        Keys not present in the struct are ignored.

    ## Examples

        iex> field = AuroraUix.Field.new(%{field: :age})
        %AuroraUix.Field{
          field: :age,
          html_type: nil,
          renderer: nil,
          name: :age,
          label: "",
          placeholder: "",
          length: 0,
          precision: 0,
          scale: 0,
          hidden: false,
          readonly: false,
          required: false
        }

        iex> AuroraUix.Field.change(field, %{html_type: :number, precision: 3})
        %AuroraUix.Field{
          field: :age,
          html_type: :number,
          renderer: nil,
          name: :age,
          label: "",
          placeholder: "",
          length: 0,
          precision: 3,
          scale: 0,
          hidden: false,
          readonly: false,
          required: false
        }
  """
  @spec change(__MODULE__.t(), map | keyword) :: __MODULE__.t()
  def change(field, attrs) when is_list(attrs) do
    keys = Map.keys(%__MODULE__{})

    attrs
    |> Enum.filter(&(elem(&1, 0) in keys))
    |> Map.new()
    |> then(&struct(field, &1))
    |> update_name()
  end

  def change(field, %{} = attrs), do: field |> struct(attrs) |> update_name()

  ## PRIVATE

  @spec update_name(__MODULE__.t()) :: __MODULE__.t()
  defp update_name(field), do: struct(field, %{name: field.field || ""})
end
