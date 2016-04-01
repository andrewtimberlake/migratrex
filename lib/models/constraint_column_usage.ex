defmodule Migratrex.ConstraintColumnUsage do
  use Migratrex.Model

  @schema_prefix "information_schema"
  schema "constraint_column_usage" do
    field :table_name
    field :column_name
    field :constraint_name
  end
end
