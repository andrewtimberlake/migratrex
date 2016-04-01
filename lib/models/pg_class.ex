defmodule Migratrex.PgClass do
  use Migratrex.Model

  schema "pg_class" do
    field :oid, :integer
    field :relname
    field :relkind
  end
end
