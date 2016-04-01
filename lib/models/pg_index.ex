defmodule Migratrex.PgIndex do
  use Migratrex.Model

  schema "pg_index" do
    field :indrelid
    field :indexrelid
    field :indisunique, :boolean
    field :indkey
  end
end
