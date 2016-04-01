defmodule Migratrex.Tables do
  use Migratrex.Model

  @schema_prefix "information_schema"
  schema "tables" do
    field :table_name
    field :table_type
    field :table_schema
  end

  def table_names do
    from t in __MODULE__,
      select: t.table_name,
       where: t.table_schema == "public",
       where: t.table_type == "BASE TABLE",
    order_by: t.table_name
  end
end
