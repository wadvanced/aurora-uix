defmodule AuroraUixWeb.Parsers.BaseParser do
  @moduledoc """
  Enables parser behaviour
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour AuroraUixWeb.Parser

      @spec add_opt(map, module, Keyword.t(), atom) :: map
      defp add_opt(parsed_opts, module, opts, key) do
        module
        |> default_value(key)
        |> then(&Keyword.get(opts, key, &1))
        |> then(&Map.put_new(parsed_opts, key, &1))
      end

      @spec capitalize(binary) :: binary
      defp capitalize(string) do
        string
        |> Macro.underscore()
        |> String.split("_")
        |> Enum.with_index(fn
          word, 0 -> String.capitalize(word)
          word, _ -> word
        end)
        |> Enum.join(" ")
      end
    end
  end
end
