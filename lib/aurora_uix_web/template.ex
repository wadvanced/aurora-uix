defmodule AuroraUixWeb.Template do
  @moduledoc """
  Templates are expected to implement this behaviour.
  """

  @uix_template Application.compile_env(:aurora_uix, :template, AuroraUixWeb.Templates.Base)

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
  generate_view(:list, %{fields: [:name, :email})
  # => quote do: ~H"<ul><li><%= @name %></li><li><%= @email %></li></ul>"

  generate_view(:card, %{title: "User Info", content: ~H"<p><%= @user %></p>"})
  # => quote do: ~H"<div class=\"card\"><h1>User Info</h1><p><%= @user %></p></div>"

  """
  @callback generate_view(type :: atom, parsed_opts :: map) :: binary

  @doc """
  Validates and return the configured uix template.
  """
  @spec uix_template() :: module
  def uix_template, do: validate(@uix_template)

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

  @spec validate(module) :: module
  defp validate(module) do
    valid? =
      module
      |> behaviour_implemented?()
      |> Kernel.and(function_exported?(module, :generate_view, 2))

    if !valid?,
      do:
        raise(
          ArgumentError,
          "The #{module} does not implement the `#{__MODULE__}` behaviour."
        )

    module
  end

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
