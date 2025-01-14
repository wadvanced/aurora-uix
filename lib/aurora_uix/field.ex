defmodule AuroraUix.Field do
  @moduledoc """
  A module representing a configurable field in the AuroraUix system.

  This module defines a struct to represent field properties for UI components, such as:
  - `name`: The field's identifier as an atom.
  - `html_type`: The HTML type of the field (e.g., `:text`, `:number`, `:date`).
  - `renderer`: A custom rendering function for the field.
  - `label`: A display label for the field.
  - `placeholder`: Placeholder text for input fields.
  - `length`: Maximum allowed length of input (used for validations).
  - `precision` and `scale`: Decimal precision and scale for numeric fields.

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
    scale: 0
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
          scale: non_neg_integer
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
        name: "age",
        label: "",
        placeholder: "",
        length: 0,
        precision: 10,
        scale: 2
      }

      iex> AuroraUix.Field.new([field: :username, html_type: :text])
      %AuroraUix.Field{
        field: :username,
        html_type: :text,
        renderer: nil,
        name: "username",
        label: "",
        placeholder: "",
        length: 0,
        precision: 0,
        scale: 0
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
        iex> AuroraUix.Field.change(field, %{html_type: :number, precision: 3})
        %AuroraUix.Field{
          field: :age,
          html_type: :number,
          renderer: nil,
          name: "age",
          label: "",
          placeholder: "",
          length: 0,
          precision: 3,
          scale: 0
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
