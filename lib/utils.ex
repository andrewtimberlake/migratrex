defmodule Migratrex.Utils do
  def singularize(word) do
    word
    |> String.replace(~r/ses$/, "ss") # double "s" which is removed at the end (hack)
    |> String.replace(~r/ches$/, "ch")
    |> String.replace(~r/ies$/, "y")
    |> String.replace(~r/s$/, "")
  end

  def capitalize(word) do
    word
    |> String.split(~r/_/)
    |> Enum.map(fn(<< first ::utf8 >> <> rest) ->
      String.upcase(<< first >>) <> rest
    end)
  end

  def get_namespace(repo), do: to_string(repo) |> String.replace(~r/Elixir\.(.+)\.Repo/, "\\1")
end
