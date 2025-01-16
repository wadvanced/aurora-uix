defmodule AuroraUixWeb.Uix.Renderer do
  @moduledoc """
  Helper module for required macros.
  """

  alias AuroraUix.Parser
  alias AuroraUixWeb.Template

  require Logger

  @uix_valid_types [:list, :card, :form]

  @doc """
  Defines the generation options for creating a full fledge view.

  ## PARAMETERS
  * `module` (module): Schema module to be used for gathering field information.
  * `type` (atom): Type of view to generate.
    * `:list` : Table like view with selectable fields and action buttons.
    * `:card` : Card like view with configurable card fields.
    * `:form` : Form like view, can have nested elements displayed as block or sections.
  * `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
    ### Common opts
    * `template: Module`: Overrides the module that handles the generation.
      By default uses AuroraUixWeb.AuroraTemplate, which is a sophisticated and highly opinionated template.
      There is also the AuroraUixWeb.PhoenixTemplate, which resembles the phoenix ui.
      The template can also be configured, application wide, by adding :aurora_uix, template: Module.
      New templates can be authored.
    * `field: (AuroraUix.Field)`: Field to be added to the default list or updated.
    * `fields: []`: Fields to be used, overrides the default list.
      The default list is created with all the fields found in the module, excluding
      the redacted fields.
    * `actions: [{:top | :bottom, function}]` : Overrides the default list of actions that are displayed at the top or bottom.
    * `add_actions: [{:top | :bottom, function}]`: Adds actions to the current list.
    * `remove: []`: List of fields to be remove from the list.
      trying to remove non-existing fields will log a warning, but no error will be raised.
    * `title: string | :hide`: Title for the view, a :hide value will make it to be ignored.
    * `sub_title: string | :hide`: Subtitle for the view, a :hide value will disallow its generation.
    * `remove_actions: [function]`: Removes actions from the current list.

    ### :list and card opts
    * `order_by: [{field, :asc | :desc}]`: Overrides the default order of the list / card.
      By default, the order is by id for numeric id, and by created_at (desc) for compose id or string id.
    * `where: string`: Adds a where like string.

    ### :card :form opts
    * `layout: Uix.Formatter`: Overrides the default layout by using a formatter. See details in the module.
  """
  defmacro define(module, type, opts \\ [])

  defmacro define(module, type, opts) when type in @uix_valid_types do
    module = Macro.expand(module, __CALLER__)
    Code.ensure_compiled(module)

    {opts, _} = Code.eval_quoted(opts)

    parsed_opts = parse_opts(module, type, opts)

    template = Template.uix_template().generate_view(type, parsed_opts)

    options = [
      engine: Phoenix.LiveView.TagEngine,
      tag_handler: Phoenix.LiveView.HTMLEngine,
      file: __CALLER__.file,
      line: __CALLER__.line + 1,
      caller: __CALLER__,
      source: template
    ]

    quote do
      var!(assigns) =
        assigns
        |> var!()
        |> Map.put(:_uix, unquote(Macro.escape(parsed_opts)))

      unquote(EEx.compile_string(template, options))
    end
  end

  defmacro define(_module, type, _opts) do
    Logger.warning("""
    The type `#{inspect(type)}` is not implemented.
    Only `#{inspect(@uix_valid_types)}` are supported.
    """)

    quote do
      var!(assigns) = assigns |> var!() |> Map.put(:type, unquote(type))

      ~H"""
      Undefined view type: {@type}
      """
    end
  end

  @doc """
  Defines a LiveView module with standard CRUD functionality for a given context, schema module, and entity type.

  Basically creates the necessary functions for:
  - Initialize the socket with a streamed list of entities.
  - Handling the navigation actions.
  - Manage editing, creating, and listing views.
  - Handling deletion of entities.

  ## Parameters

  - `context` - The module that defines the context for the application (e.g., the boundary module containing CRUD functions). This is expanded at compile time.
  - `module` - The schema module representing the resource (e.g., an Ecto schema). This is also expanded at compile time.
  - `type` - The type of the view to generate being managed (used to determine naming conventions for helper functions).
  - `opts` - A keyword list of options to configure the generated LiveView module.

  ## Generated Behavior

  The macro expects the provided context and module to define the following functions:

  - `list_<source>()` - Returns a list of all entities for streaming.
  - `get_<schema_module>!(id)` - Fetches a specific entity by its ID.
  - `delete_<schema_module>(instance)` - Deletes a specific entity.

  ### Example Usage

  ```elixir
  defmodule MyAppWeb.UserLive.Index do
    use MyAppWeb, :live_view
    use AuroraUixWeb.Uix

    view MyApp.Accounts, MyApp.Accounts.User, :list, [source: "users", name: "User", title: "Users"]
  end
  """
  defmacro view(context, module, types, opts) do
    context = Macro.expand(context, __CALLER__)
    module = Macro.expand(module, __CALLER__)
    types = if is_list(types), do: types, else: [types]

    Code.ensure_compiled(context)
    Code.ensure_compiled(module)

    generated_code =
      for type <- types do
        parsed_opts = parse_opts(module, type, opts)
        Template.uix_template().generate_module(context, module, type, opts, parsed_opts)
      end

    quote do
      (unquote_splicing(generated_code))
    end
  end

  ## PRIVATE

  @spec validate_module(module) :: module
  defp validate_module(module) do
    with {:module, module} <- Code.ensure_compiled(module),
         true <- function_exported?(module, :__schema__, 1) do
      module
    else
      _ ->
        raise(
          ArgumentError,
          "The #{module} is not an Ecto.Schema"
        )
    end
  end

  @spec parse_opts(module, atom, Keyword.t()) :: map
  defp parse_opts(module, type, opts) do
    module
    |> validate_module()
    |> Parser.parse(type, opts)
  end
end
