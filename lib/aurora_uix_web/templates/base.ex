defmodule AuroraUixWeb.Templates.Base do
  @moduledoc """
  A module for generating basic HEEx templates for different UI component types.

  This module provides a single function, `generate_view/2`,
  which creates HEEx template fragments based on the specified type.
  Currently, it supports the following types:

  - `:list`: Generates a template for a list.
  - `:card`: Generates a template for a card.
  - `:form`: Generates a template for a form.

  ## Examples

  ```elixir
  iex> AuroraUixWeb.Templates.Base.generate_view(:list, %{})
  # => "<h1>Base Template</h1>list"

  iex> AuroraUixWeb.Templates.Base.generate_view(:card, %{})
  # => "<h1>Base Template</h1>card"

  iex> AuroraUixWeb.Templates.Base.generate_view(:form, %{})
  # => "<h1>Base Template</h1>form"
  """

  @behaviour AuroraUixWeb.Template

  alias AuroraUixWeb.Template

  @doc """
  Generates a basic HEEx template fragment for the specified type.

  ## Parameters

  - `type` (`atom`): Specifies the type of template to generate.
    Supported values: `:list`, `:card`, `:form`.

  - `parsed_opts` (`map`): A map of options (currently unused in this implementation).

  ## Returns

  - (`binary`): A HEEx template corresponding to the specified type.

  ## Examples

  ```elixir
  generate(:list, %{})
  # => "<h1>Base Template</h1>list"

  generate(:card, %{})
  # => "<h1>Base Template</h1>card"

  generate(:form, %{})
  # => "<h1>Base Template</h1>form"
  """
  @spec generate_view(atom, map) :: binary
  def generate_view(:list, parsed_opts) do
    parsed_opts =
      parsed_opts
      |> columns()
      |> then(&Map.put(parsed_opts, :columns, &1))

    Template.interpolate(
      parsed_opts,
      ~S"""
        <.header>
          Listing [[title]] 002
          <:actions>
            <.link patch={~p"/[[source]]/new"}>
              <.button>New [[title]]</.button>
            </.link>
          </:actions>
        </.header>

        <.table
            id={"uix-[[source]]"}
            rows={get_in(assigns, @_uix.rows)}
            row_click={fn {_id, row} -> JS.navigate(~p"/[[source]]/#{row}") end}
        >
          [[columns]]
          <:action :let={{_id, entity}}>
            <div class="sr-only">
              <.link navigate={~p"/[[source]]/#{entity}"}>Show</.link>
            </div>
            <.link patch={~p"/[[source]]/#{entity}/edit"}>Edit</.link>
          </:action>
          <:action :let={{id, entity}}>
            <.link
              phx-click={JS.push("delete", value: %{id: entity.id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
            >
              Delete
            </.link>
          </:action>
        </.table>

        <.modal :if={@live_action in [:new, :edit]} id="account-modal" show on_cancel={JS.patch(~p"/[[source]]")}>
          <.live_component
            module={AuroraUixDemoWeb.AccountLive.FormComponent}
            id={@account.id || :new}
            title={@page_title}
            action={@live_action}
            account={@account}
            patch={~p"/[[source]]"}
          />
        </.modal>
      """
    )
  end

  def generate_view(:card, _parsed_opts) do
    ~S"""
      <h1>Base Template</h1>
    card
    """
  end

  def generate_view(:form, _parsed_opts) do
    ~S"""
      <h1>Base Template</h1>
    form
    """
  end

  @doc """
  Generates a LiveView module definition for the specified `type`, including functions for rendering,
    mounting, and handling events and parameters.

  Basically creates the necessary functions for:
  - Initialize the socket with a streamed list of entities.
  - Handling the navigation actions.
  - Manage editing, creating, and listing views.
  - Handling deletion of entities.

  ## Parameters

    - `context` (`module`): The module that provides the data access functions, such as `list_`, `get_`, and `delete_`.
    - `module` (`module`): The Ecto schema module or context module used for data operations.
    - `type` (`atom`): Specifies the type of UI component to generate. Currently, only `:list` is supported.
    - `opts` (`Keyword.t()`): A map of options passed to customize the generated LiveView module.
    - `parsed_opts` (`map`): A map of parsed options containing precomputed values such as the source name,
    module name, and titles for use in the generated module.

  ## Returns

      - (`Macro.t()`): A quoted expression representing the generated module definition.

  ## Generated Behavior

  The function expects the provided context and module to define the following functions:

  - `list_<source>()` - Returns a list of all entities for streaming.
  - `get_<schema_module>!(id)` - Fetches a specific entity by its ID.
  - `delete_<schema_module>(instance)` - Deletes a specific entity.

  ## Notes

  - The generated module provides standard LiveView functionality, including dynamic assignment
  of page titles and CRUD operations for the specified schema or context module.
  """
  @spec generate_module(module, module, module, atom, Keyword.t(), map) :: Macro.t()
  def generate_module(web, context, module, :list = type, opts, parsed_opts) do
    key = String.to_existing_atom(parsed_opts.source)
    list_function = String.to_existing_atom("list_#{parsed_opts.source}")
    get_function = String.to_existing_atom("get_#{parsed_opts.module}!")
    delete_function = String.to_existing_atom("delete_#{parsed_opts.module}")

    quote do
      defmodule List do
        use unquote(web), :live_view

        alias unquote(context)
        alias unquote(module)

        @impl true
        def render(assigns) do
          var!(assigns) = Map.merge(%{}, assigns)
          define(unquote(module), unquote(type), unquote(opts))
        end

        @impl true
        def mount(_params, _session, socket) do
          {:ok, stream(socket, unquote(key), apply(unquote(context), unquote(list_function), []))}
        end

        @impl true
        def handle_params(params, _url, socket) do
          {:noreply, apply_action(socket, socket.assigns.live_action, params)}
        end

        @impl true
        def handle_event("delete", %{"id" => id}, socket) do
          instance = apply(unquote(context), unquote(get_function), [id])

          {:ok, _} = apply(unquote(module), unquote(delete_function), [instance])

          {:noreply, stream_delete(socket, unquote(key), instance)}
        end

        @impl true
        def handle_info({_component, {:saved, account}}, socket) do
          {:noreply, stream_insert(socket, :accounts, account)}
        end

        ## PRIVATE

        @spec apply_action(Phoenix.LiveView.Socket.t(), atom, map) :: Phoenix.LiveView.t()
        defp apply_action(socket, :edit, %{"id" => id}) do
          socket
          |> assign(:page_title, "Edit #{unquote(parsed_opts.name)}")
          |> assign(:account, apply(unquote(context), unquote(get_function), [id]))
        end

        defp apply_action(socket, :new, _params) do
          socket
          |> assign(:page_title, "New #{unquote(parsed_opts.name)}")
          |> assign(:account, %unquote(module){})
        end

        defp apply_action(socket, :index, _params) do
          socket
          |> assign(:page_title, "Listing #{unquote(parsed_opts.title)}")
          |> assign(:account, nil)
        end
      end
    end
  end

  def generate_module(_web, _context, _module, _type, _opts, _parsed_opts) do
    quote do
      # no generation
    end
  end

  ## PRIVATE

  @spec columns(map) :: binary
  defp columns(%{fields: fields}) do
    Enum.map_join(fields, "\n", fn field ->
      "<:col :let={{_id, entity}} label=\"#{field.label}\">{entity.#{field.name}}</:col>"
    end)
  end

  defp columns(_parsed_opts), do: ""
end
