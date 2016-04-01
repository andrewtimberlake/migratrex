defmodule Migratrex.Columns do
  use Migratrex.Model

  @schema_prefix "information_schema"
  schema "columns" do
    field :table_schema
    field :table_name
    field :column_name
    field :column_default
    field :is_nullable, :boolean
    field :data_type
    field :ordinal_position, :integer
    field :character_maximum_length, :integer
  end

  def columns(table_name) do
    from t in __MODULE__,
      select: %{column_name: t.column_name,
                is_nullable: t.is_nullable,
                column_default: t.column_default,
                data_type: t.data_type,
                character_maximum_length: t.character_maximum_length,
               },
       where: t.table_schema == "public",
       where: t.table_name == ^table_name,
    order_by: t.ordinal_position
  end
end
