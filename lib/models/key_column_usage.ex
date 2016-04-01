defmodule Migratrex.KeyColumnUsage do
  use Migratrex.Model

  @schema_prefix "information_schema"
  schema "key_column_usage" do
    field :constraint_name
    field :column_name
  end
end
