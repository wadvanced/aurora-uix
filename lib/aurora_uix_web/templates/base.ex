defmodule AuroraUixWeb.Templates.Base do
  @moduledoc """
  A module for generating basic HEEx templates for different UI component types.

  This module provides a single function, `generate/2`,
  which creates HEEx template fragments based on the specified type.
  Currently, it supports the following types:

  - `:list`: Generates a template for a list.
  - `:card`: Generates a template for a card.
  - `:form`: Generates a template for a form.

  ## Examples

  ```elixir
  iex> AuroraUixWeb.Templates.Base.generate(:list, %{})
  # => "<h1>Base Template</h1>list"

  iex> AuroraUixWeb.Templates.Base.generate(:card, %{})
  # => "<h1>Base Template</h1>card"

  iex> AuroraUixWeb.Templates.Base.generate(:form, %{})
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
  @spec generate(atom, map) :: binary
  def generate(:list, parsed_opts) do
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
          <:col :let={{_id, account}} label="Number">{account.number}</:col>
          <:col :let={{_id, account}} label="Description">{account.description}</:col>
          <:action :let={{_id, account}}>
            <div class="sr-only">
              <.link navigate={~p"/[[source]]/#{account}"}>Show</.link>
            </div>
            <.link patch={~p"/[[source]]/#{account}/edit"}>Edit</.link>
          </:action>
          <:action :let={{id, account}}>
            <.link
              phx-click={JS.push("delete", value: %{id: account.id}) |> hide("##{id}")}
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

  def generate(:card, _parsed_opts) do
    ~S"""
      <h1>Base Template</h1>
    card
    """
  end

  def generate(:form, _parsed_opts) do
    ~S"""
      <h1>Base Template</h1>
    form
    """
  end
end
