defmodule Migratrex.PgAttribute do
  use Migratrex.Model

  schema "pg_attribute" do
    field :attrelid
    field :attnum
    field :attname
  end
end
