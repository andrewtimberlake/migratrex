defmodule Migratrex.TableConstraints do
  use Migratrex.Model

  @schema_prefix "information_schema"
  schema "table_constraints" do
    field :constraint_name
    field :table_name
    field :constraint_type
  end
end
