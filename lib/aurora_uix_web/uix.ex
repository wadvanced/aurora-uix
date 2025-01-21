defmodule AuroraUixWeb.Uix do
  @moduledoc """
  Provides tools for low-code, highly opinionated view rendering and handling in Phoenix applications.

  This module introduces two key features:

  1. `uix_schema_metadata`: Adds UI-specific metadata to schemas to enhance their rendering capabilities in forms, lists, and other views.
  2. `uix_define`: Allows for the composition of UI layouts and interaction logic by leveraging schema metadata.

  ## `uix_schema_metadata`

  Ecto schemas typically lack the metadata required for rendering user interfaces effectively.
  This macro enriches schemas with metadata for UI purposes, such as field visibility, placeholders, validation rules, and layout grouping.

  ### Example:

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
    end
  ```

  ## `uix_define`
  This macro defines the layout and behavior of the views and components to be rendered.
  It relies on the metadata defined through uix_schema_metadata to determine field characteristics.

  ### Example
  ```elixir
    defmodule MyAppWeb.ProductLive.Index do
      uix_define do
        layout :form, :component do
          group "Product" do
            line product: name, product: price
          end
          group "Category Details" do
            line category: (field :name, readonly: true)
          end
          tab "Sales" do
            line _assigns: :last_quarter
          end
          tab "Forecast" do
            group "Next Semester" do
              line forecast: :quantities
              line forecast: :revenues
            end
            group "Next Year" do
              line forecast_next: :quantities
              line forecast_next: :revenues
            end
          end
        end

        layout :list, :index do
          row :category_name, :product_name, :product_quantity
        end
      end
    end
  ```

  """
  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Uix
  alias AuroraUixWeb.Uix.SchemaMetadata

  require Logger

  defmacro __using__(_opts) do
    quote do
      import Uix
      Module.register_attribute(__MODULE__, :auix_schemas, persist: true)
    end
  end

  defmacro uix_schema_metadata(name, schema, context \\ nil, do_block \\ nil) do
    quote do
      import SchemaMetadata

      SchemaMetadata.__uix_metadata__(
        __MODULE__,
        unquote(name),
        unquote(schema),
        unquote(context)
      )

      unquote(do_block[:do])
    end
  end

  defmacro uix_define(do: block) do
    module = __CALLER__.module

    quote do
      import AuroraUixWeb.Uix.Define
      unquote(block)
    end
  end
end
