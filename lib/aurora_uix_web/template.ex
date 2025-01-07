defmodule AuroraUixWeb.Template do
  @moduledoc """
  Templates are expected to implement this behaviour.
  """

  @doc """
  Generates a HEEx code fragment for the specified type and options.

  ## Parameters

  - `type` (`atom`): Specifies the type of UI component to generate.
    The types implemented and supported by the library are: `:list`, `:card`, `:form`.

  - `parsed_opts` (`map`): A map with the customized value for the generated HEEx code.

  ## Returns

  - (`Macro.t()`): The generated HEEx code fragment as a quoted expression.

  ## Examples

  ```elixir
  generate(:list, %{fields: [:name, :email})
  # => quote do: ~H"<ul><li><%= @name %></li><li><%= @email %></li></ul>"

  generate(:card, %{title: "User Info", content: ~H"<p><%= @user %></p>"})
  # => quote do: ~H"<div class=\"card\"><h1>User Info</h1><p><%= @user %></p></div>"

  """
  @callback generate(type :: atom, parsed_opts :: map) :: binary

  @doc """
  Validates that the given module implements the current behaviour (`#{__MODULE__}`).

  This function checks two things:
  1. The module has declared the `#{__MODULE__}` behaviour via the `@behaviour` attribute.
  2. The module exports the required functions.

  If either of these conditions is not met, it raises an `ArgumentError`.

  ## Parameters

    - `module` (`module`): The module to validate.

  ## Returns

    - (`module`): The same module, if it is valid.

  ## Raises

    - `ArgumentError`: If the module does not implement the required behaviour or does not define the `generate/2` function.

  ## Examples

    ```elixir
    defmodule ValidModule do
      @behaviour AuroraUixWeb.Template
      def generate(:example, _parsed_opts), do: :ok
    end

    defmodule InvalidModule do
      def generate(:example, _parsed_opts), do: :ok
    end

    AuroraUixWeb.Template.validate(ValidModule)
    # => ValidModule

    AuroraUixWeb.Template.validate(InvalidModule)
    # => ** (ArgumentError) The InvalidModule does not implement the `AuroraUixWeb.Template` behaviour.
  """
  @spec validate(module) :: module
  def validate(module) do
    valid? =
      module
      |> behaviour_implemented?()
      |> Kernel.and(function_exported?(module, :generate, 2))

    if !valid?,
      do:
        raise(
          ArgumentError,
          "The #{module} does not implement the `#{__MODULE__}` behaviour."
        )

    module
  end

  @doc """
  Interpolates [[key]] with the string value. Ensures that the returned template has the least amount of
  dynamic contents.

  ## Parameters
    - `template (binary)`: The template to apply the interpolation.
    - `parsed_options (map)`: Options to use.
  """
  @spec interpolate(map, binary) :: binary
  def interpolate(parsed_options, template) do
    Enum.reduce(parsed_options, template, &replace/2)
  end

  ## PRIVATE FUNCTIONS

  @spec behaviour_implemented?(module) :: boolean
  defp behaviour_implemented?(module) do
    :attributes
    |> module.__info__()
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(__MODULE__)
  end

  @spec replace(tuple, binary) :: binary
  defp replace({key, value}, template) when is_binary(value) do
    String.replace(template, "[[#{key}]]", value)
  end

  defp replace({key, value}, template), do: replace({key, inspect(value)}, template)
end
